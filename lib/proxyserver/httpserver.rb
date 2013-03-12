#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'

class HttpServer < ProxyServer
	#config['host']  config['port'] config['forward_host'] config['forward_port']
	def initialize(config)
		@http=Http::Parser.new
		super(config)
	end

	def decode_req(req)
		@http.parse req
		p @http
		p req
		req
	end
	def decode_res(res)
		@http.parse res
		p @http
		p res
		res
	end
end


