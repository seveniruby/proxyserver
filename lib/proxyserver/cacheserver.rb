#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'


require 'rubygems'
require 'eventmachine'

class CacheStubServer < EventMachine::Connection
	def post_init
		puts "-- someone connected to the echo server!"
	end

	def receive_data data
		begin
			@@config['data'][data].each do |d|
				send_data d
			end
		rescue
			send_data 'HTTP/1.1 200 OK
Content-Length: 4

miss'
		end

	end

	def self.start
		begin
			@@thread=Thread.new  do
				EventMachine::run do
					@@server=EventMachine::start_server @@config['host'], @@config['port'], self
					puts "cache server start on port #{@@config['port']}"
					p @@server

					EventMachine.add_periodic_timer(10) {
						p @@thread
						p @@server
					}


				end
			end
		rescue Exception=>e
			puts "ERROR________________"
			puts e
		end
		self
	end

	def self.start_in_loop
		EventMachine.add_timer(1) {
			@@server=EventMachine::start_server @@config['host'], @@config['port'], self
			puts "#{@@server} start on port #{@@config['port']}"
			p @@server
		}
		self

	end


	def self.stop
		EventMachine.stop_server @@server
		sleep 1
		self
	end

	def self.config(config)
		@@config=config
		self
	end

	def self.update(data)
		@@config['data']=data
	end

end



class CacheServer < ProxyServer
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
	def decode_res(res)
		@cache_data[@req]<<res
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
	def callback(&blk)
		@blk=blk
	end
end





