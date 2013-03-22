#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'
require 'eventmachine'


class CacheProxy < ProxyServer
	#config['host']  config['port'] config['forward_host'] config['forward_port']
	def initialize(config)
		@cache_data={}
		@req=nil
		@res=nil
		@cache_enable=false
		super config
	end

	def decode_req(req)
		@req=req
		@cache_data[@req]=[]
		req
	end
	# one request may be correspond to multi response, just like http
	def decode_res(res)
		@cache_data[@req]<<res if @cache_data[@req]
		@blk.call if @blk
		res
	end
	def encode_req(req)
		req
	end
	def encode_res(res)
		res
	end

	def data()
		@cache_data
	end
	# when response return, it will be called, used for assign data to cacheserver
	def callback(&blk)
		@blk=blk
	end
end


