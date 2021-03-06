require 'net/http'
require 'json'

module Doxie
  class Client
    class Error < StandardError; end
    class ClientError < Error; end
    class ServerError < Error; end
    class AuthenticationError < ClientError; end

    USERNAME = 'doxie'.freeze

    attr_accessor :ip, :password

    def initialize options
      @ip = options[:ip] || ''
      @password = options[:password] || ''
    end

    def hello
      get('/hello.json')
    end

    def hello_extra
      get('/hello_extra.json')
    end

    def restart
      get('/restart.json')
    end

    def scans
      get('/scans.json')
    end

    def recent_scans
      get('/scans/recent.json')
    end

    def scan scan_name, file_name = nil
      file "/scans#{scan_name}", file_name
    end

    def thumbnail scan_name, file_name = nil
      file "/thumbnails#{scan_name}", file_name
    end

    def delete_scan scan_name
      delete("/scans#{scan_name}")
    end

    def delete_scans scan_names
      post("/scans/delete.json", scan_names)
    end

    private

    def get path
      uri = uri_for(path)
      message = Net::HTTP::Get.new(uri.request_uri)
      parse(request(uri, message))
    end

    def post path, params
      uri = uri_for(path)
      message = Net::HTTP::Post.new(uri.request_uri)
      message.body = JSON.generate(params)
      parse(request(uri, message))
    end


    def delete path
      uri = uri_for(path)
      message = Net::HTTP::Delete.new(uri.request_uri)
      parse(request(uri, message))
    end

    def uri_for path
      URI("https://#{ip}:8080#{path}")
    end

    def request(uri, message)
      message.basic_auth USERNAME, password if password
      http = Net::HTTP.new(uri.host, uri.port)
      http.request(message)
    end

    def parse response
      case response
      when Net::HTTPNoContent
        return true
      when Net::HTTPSuccess
        if response['Content-Type'].split(';').first == 'application/json'
          JSON.parse(response.body)
        else
          response.body
        end
      when Net::HTTPUnauthorized
        raise AuthenticationError, "#{response.code} response from #{ip}"
      when Net::HTTPClientError
        raise ClientError, "#{response.code} response from #{ip}"
      when Net::HTTPServerError
        raise ServerError, "#{response.code} response from #{ip}"
      else
        raise Error, "#{response.code} response from #{ip}"
      end
    end

    def file scan_name, file_name
      body = get(scan_name)
      if file_name
        File.open(file_name, 'wb') { |file| file.write(body) }
        true
      else
        body
      end
    end
  end
end
