#encoding: utf-8
require 'rubygems'
require 'em-proxy'
require 'yaml'
require 'json'
require 'base64'
require 'proxyserver/stub_server'

#解决jruby下的一个bug
module EventMachine
	class Connection
		def close_connection after_writing = false
			EM.next_tick do
				EventMachine::close_connection @signature, after_writing
			end
		end
	end
end

class ProxyServer
	#config['host']  config['port'] config['forward_host'] config['forward_port']
	def initialize(config)
		@config=config
		@proxy=nil
		@stub=nil
		@mocks=[]
		@req=nil
		@res=nil
		@raw_req=nil
		@raw_res=nil
	end

	def decode_req(raw_req)
		p 'decode req'
		@req=raw_req
	end
	def decode_res(raw_res)
		p 'decode res'
		@res=raw_res
	end
	def encode_req(req)
		p 'encode_req'
		p req
		@raw_req=req
		@raw_req
	end

	def encode_res(res)
		p 'encode_res'
		p res
		@raw_res=res
		@raw_res
	end
	def mock_req_res
		@mocks.each do |m|
			@res=m.call @req
			p "mock"
			p @req
			p @res
		end
	end

	def mock(&blk)
		@mocks<< blk
	end

	def run(conn)
		if @config['forward_host']
			conn.server :forward, :host =>@config['forward_host'], :port =>@config['forward_port']||80
		else
			@stub=StubServer.new
			@stub.start			
			conn.server :forward, :host =>'127.0.0.1', :port =>65530
		end
		# modify / process request stream
		conn.on_data do |raw_req|
			@raw_req=raw_req
			@req=self.decode_req(raw_req)
			@raw_req=self.encode_req(@req)
			@raw_req
		end
		# modify / process response stream
		conn.on_response do |backend, raw_res|
			@raw_res=raw_res
			@res=self.decode_res(raw_res)
			mock_req_res
			@raw_res=self.encode_res(@res)
			#需要增加多转发时候的请求销毁
			@raw_res
		end

		# termination logic
		conn.on_finish do |backend, name|
			# terminate connection (in duplex mode, you can terminate when prod is done)
			# unbind if backend == :srv
		end
	end

	def start
		server=self
		Thread.new do
			begin
				proxy_start(:host=>@config['host'], :port=>@config['port'], :debug=>true) do |conn|
					server.run conn
				end
			rescue Exception=>e
				puts e
			end
		end
	end

	def proxy_start(options, &blk)
		#EM.epoll
		EM.run do
			@proxy=EventMachine::start_server(options[:host], options[:port], EventMachine::ProxyServer::Connection, options) do |c|
				c.instance_eval(&blk)
			end
		end
	end

	def stop
		puts "Terminating ProxyServer"
		p @proxy
		EventMachine.stop_server @proxy
		EventMachine.stop_event_loop
		sleep 1
	end
end


