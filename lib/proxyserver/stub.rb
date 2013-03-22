#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'
require 'eventmachine'

class Stub < EventMachine::Connection
	@mock||=[]

	def initialize(*args)
		@config=args[0]
	end

	def post_init
		puts "-- someone connected to the #{self} server!"
	end

	def receive_data req
		begin
			res=@config['data'][req]
			if @mock
				@mock.each do |m|
					res=m.call(req, res)
				end
			end
			if res.class==Array
				res.each do |d|
					send_data d
				end
			else
				send_data res
			end
		rescue Exception=>e
			puts "ERROR________"
			puts e.message
			puts e.backtrace
			send_data 'HTTP/1.1 200 OK
Content-Length: 4

miss'
		end

	end

	def start(debug=false)
		begin
			if !EventMachine.reactor_running?
				p "EM.run"
				@thread=Thread.new  do
					EventMachine::run do
						start_server
						#jruby的eventmachine跟ruby版本的行为不一致，需要添加这个block保证tick的运转，否则就会block
						EventMachine.add_periodic_timer(2) {
						}
					end
				end
				sleep 2
			else
				start_in_loop
			end
		rescue Exception=>e
			puts "ERROR________________"
			puts e.message
			puts e.backtrace
		end
		sleep 1
	end

	def start_server
		@server=EventMachine::start_server @config['host'], @config['port'], self.class, @config
		puts "#{self} #{@server} start on port #{@config['port']}"
	end

	def start_in_loop(debug=false)
		EventMachine.add_timer(1) {
			start_server
		}
=begin
		EventMachine.add_periodic_timer(5) {
			p self
			p @thread
		}
		self
=end

	end


	def stop
		EventMachine.stop_server @server
	end


	def update(data)
		@config['data']=data
		p @config
	end

	def mock(&blk)
		@mock||=[]
		@mock<<blk
	end

end






