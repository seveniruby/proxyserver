require 'rubygems'
require 'eventmachine'

class EchoServer < EventMachine::Connection
	def post_init
		puts "-- someone connected to the echo server!"
	end

	def receive_data data
		send_data 'HTTP/1.1 200 OK
Content-Length: 4

stub'

	end
end

class StubServer
	def initialize(port=nil)
		@server=nil
		@port=port||65530
	end
	def start
		Thread.new  do
			EventMachine::run {
				@server=EventMachine::start_server "127.0.0.1", @port, EchoServer
				puts "running echo server on #{@port}"
				p @server
			}
		end
		sleep 1
	end

	def stop
		EventMachine.stop_server @server
		sleep 1
	end
end



