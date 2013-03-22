#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'
require 'eventmachine'

class CacheServer < EventMachine::Connection
	def post_init
		puts "-- someone connected to the echo server!"
	end

	def receive_data data
		begin
			p self
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
						File.open('cache.data', 'w') do |f|
							f.puts @@config.to_yaml
						end
					}


				end
			end
		rescue Exception=>e
			puts "ERROR________________"
			puts e
		end
		self
	end

	def self.start_in_loop(debug)
		EventMachine.add_timer(1) {
			@@server=EventMachine::start_server @@config['host'], @@config['port'], self, :debug=>debug
			puts "#{self} #{@@server} start on port #{@@config['port']}"
		}
		EventMachine.add_periodic_timer(10) {
			File.open('cache.data', 'w') do |f|
				f.puts @@config.to_yaml
			end
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






