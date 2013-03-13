#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'iso8583'
require 'iso8583/berlin'


class ISO8583Server < ProxyServer
	#config['host']  config['port'] config['forward_host'] config['forward_port']
	def initialize(config)
		@berlin = BerlinMessage.new
		super(config)
	end

	def encode_req(req)
		@berlin.to_b
	end

	def decode_req(raw_req)
		p raw_req
		@berlin=BerlinMessage.parse raw_req
		p @berlin
		@berlin

	end
	def decode_res(res)
		p raw_res
		@berlin=BerlinMessage.parse raw_req
		p @berlin
		@berlin
	end
end


