#encoding: utf-8
#require 'rubygems'
require 'proxy_server'
require 'webrick'


#还没有完工，还没有选择好使用哪个http的解析器，考虑用em-http-request重写整个http的proxy
#目前先用简单的http parser代替着用，因为proxy接管了网络交互，所以比较难判断http的response到底何时结束
#可能需要深入em中hack代码才行，我很好奇em-http-request是如何做的
module ProxyServer
  class HttpProxy < ProxyServer
    #config['host']  config['port'] config['forward_host'] config['forward_port']
    def initialize(config)
      @res=''
      #lazy load
      require 'http_parser.rb'
      require 'http/parser'
      @http_res=parser_init
      @http_req=parser_init
      super(config)
    end


    def gzip(string)
      Zlib::GzipReader.new(StringIO.new(string)).read
      #Zlib::Inflate.inflate(string)
    end

    #http_parser.rb miss chunk, it's a bug
    def parser_init
      http=Http::Parser.new
      http.on_headers_complete = proc do
        #p http.headers
      end
      http.on_body = proc do |chunk|
        # One chunk of the body
      end

      http.on_message_complete = proc do |env|
        # Headers and body is all parsed
        #puts "Done!"
      end
      http
    end

    def decode_request(req)
      req.data={}
      finish=false
      @http_req.on_headers_complete = proc do
        #p http.headers
        req.data['head']=@http_req.headers

      end
      @http_req.on_body = proc do |chunk|
        # One chunk of the body
        req.data['body']=chunk
      end
      @http_req.on_message_complete = proc do |env|
        finish=true
      end
      @http_req<<req.raw
      #代理方式使用request_url，非代理方式使用request_path.split[0]
      #http parser有个bug
      req.data['request']="#{@http_req.http_method} #{@http_req.request_url} HTTP/1.1"
      while !finish
        sleep 1
      end
    end

    def encode_request(req)
      old=req.raw
      req.raw=req.data['request']+"\r\n"
      req.raw+=req.data['head'].map{ |k,v| "#{k}: #{v}" }.join("\r\n")
      req.raw+="\r\n\r\n"
      req.raw+=req.data['body']||''
      if old!=req.raw
        p "Warnning encode diff from old to new"
        p "old"
        p old
        p "new"
        p req.raw
      end
    end

    #需要增加编解码
    def decode_response(res)
      @http_res<< res.raw
=begin
      @http_res.on_body = proc do |chunk|
        # One chunk of the body
        res.data
      end
=end
      super
    end
  end
end


