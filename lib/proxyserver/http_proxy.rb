#encoding: utf-8
#require 'rubygems'
require 'proxy_server'
require 'webrick'

class HttpProxy < ProxyServer
  #config['host']  config['port'] config['forward_host'] config['forward_port']
  def initialize(config)
    @res=''
    #parser_init
    super(config)
  end

  #http_parser.rb miss chunk, it's a bug
  def parser_init
    @http = Http::Parser.new
    @http.on_headers_complete = proc do
      p @http.headers
    end
    @http.on_body = proc do |chunk|
      # One chunk of the body
      p chunk
    end

    @http.on_message_complete = proc do |env|
      # Headers and body is all parsed
      puts "Done!"
    end


  end

  def decode_req(req)
    req.data=req.raw
  end

  def encode_req(req)

  end

  def decode_res(res)
    res.data=res.raw
=begin
          if @res.gsub("\r\n\r\n").count==2
            p 'res'
            res.raw=@res
            @res=''
          end
=end

  end

  def encode_res(res)

  end

end


