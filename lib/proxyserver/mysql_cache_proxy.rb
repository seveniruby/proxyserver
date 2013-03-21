#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'
require 'eventmachine'

class MysqlCacheStubServer < CacheServer
	def post_init
		@logo="9\x00\x00\x00\n5.0.51b-log\x00"
		@login="M\x00\x00\x01\r\xA2\x00\x00\x00\x00\x00@\x1C\x00\x00"
		puts "-- someone connected to the echo server!"
	end

	def receive_data data
		begin
			if !@@config['data']['login']
				@@config['data'].keys.each do |k|
					if k.index(@login)
						@@config['data']['login']=@@config['data'][k]
					end
				end

			end
			if data.index(@login)
				p "login"
				reply=@@config['data']['login']
			else
				reply=@@config['data'][data]
			end
			reply.each do |d|
				send_data d
			end
		rescue
			send_data 'HTTP/1.1 200 OK
Content-Length: 4

miss'
		end

	end

end


