#encoding: utf-8
require 'rubygems'
require 'proxy_server'
require 'http_parser'
require 'http/parser'
require 'uri'
require 'cgi'

module ProxyServer
  class FormProxy < ProxyServer
    def initialize(config)
      @http=Http::Parser.new
      @res_http=""
      @data={}
      super(config)
    end

    def decode_req(req)
      begin
        @raw_req=req
        @http.parse req
        @data['req']={}
        p @http.path
        p URI.parse(@http.path).query
        @data['req']['get']=CGI.parse(URI.parse(@http.path).query)
        @data['req']['post']=@http.body
      rescue Exception => e
        puts '================'
        puts e.message
        puts e.backtrace
      end
      @data['req']
    end

    def encode_req(req)
      @raw_req

    end

    def decode_res(res)
      @raw_res=res
      begin
        @http.parse res
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
      p @data
      res=''
      res
    end

    def encode_res(res)
      @raw_res
    end
  end
end


