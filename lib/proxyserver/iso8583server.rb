#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'iso8583'
require 'iso8583/berlin'


class ISO8583Server < ProxyServer
	#config['host']  config['port'] config['forward_host'] config['forward_port']
	def initialize(config)
		super(config)
	end

	def encode_req(req)
		req.to_b
	end
	def encode_res(res)
		res.to_b
	end

	def decode_req(raw_req)
		p raw_req
		@berlin=BerlinMessage.parse raw_req
		p @berlin
		@berlin

	end
	def decode_res(raw_res)
		p "iso decode_res"
		p raw_res
		@berlin=BerlinMessage.parse raw_res
		p @berlin
		@berlin
	end
end


