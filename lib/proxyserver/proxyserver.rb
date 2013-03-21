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
		@thread=nil
		@proxy=nil
		@stub=nil
		@mocks=[]
		@req=nil
		@res=nil
		@raw_req=nil
		@raw_res=nil
	end

	#解码二进制，返回可读数据
	def decode_req(raw_req)
		p 'decode req'
		@req=raw_req
		@req
	end
	#解码二进制，返回可读数据
	def decode_res(raw_res)
		p 'decode res'
		@res=raw_res
		@res
	end
	#可读数据组装为二进制
	def encode_req(req)
		p 'encode_req'
		@raw_req=req
		#简单返回，用户需要自己重载
		@raw_req
	end

	def encode_res(res)
		p 'encode_res'
		@raw_res=res
		@raw_res
	end
	def mock_req_res(req, res)
		@mocks.each do |m|
			@res=m.call(req,res)
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
			mock_req_res @req, @res
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

	def start(debug=false)
		server=self
		begin
			@thread=Thread.new do
				proxy_start(:host=>@config['host'], :port=>@config['port'], :debug=>debug) do |conn|
					server.run conn
				end
			end
		rescue Exception=>e
			puts "ERROR________________"
			puts e
		end
		puts "#{self} server start on port #{@config['port']}"
	end
	def start_in_loop(debug=false)
		server=self
		@proxy=EventMachine::start_server(@config['host'],@config['port'], EventMachine::ProxyServer::Connection, :debug=>debug) do |conn|
			server.run conn
		end
		EventMachine.add_periodic_timer(10) {
			p @thread
			p @proxy
		}
		puts "#{self} start on port #{@config['port']}"
	end

	def proxy_start(options, &blk)
		#EM.epoll
		EM.run do
			@proxy=EventMachine::start_server(options[:host], options[:port], EventMachine::ProxyServer::Connection, options) do |c|
				c.instance_eval(&blk)
			end
			EventMachine.add_periodic_timer(10) {
				p @thread
				p @proxy
			}
		end
	end

	def stop
		puts "Terminating ProxyServer"
		p @proxy
		EventMachine.stop_server @proxy
		EventMachine.stop_event_loop
		sleep 1
	end

	def keep
		p @thread
		@thread.join
	end
end


