#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'http/parser'
require 'eventmachine'

class MysqlCacheServer < CacheServer
	#被jruby狠坑，类的静态变量和类实例之间的访问关系在ruby和jruby之间不一致
	#@@config||={}
	@@logo="9\x00\x00\x00\n5.0.51b-log\x00h0\x02\x00x.u)eEgX\x00,\xA2!\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00cfXg|Y*`)Jv7\x00"
	@@reply="\a\x00\x00\x02\x00\x00\x00\x02\x00\x00\x00"
	@@login="M\x00\x00\x01\r\xA2\x00\x00\x00\x00\x00"
	def post_init
		puts "-- someone connected to the #{self} server!"
		send_data @@logo
	end

	def receive_data data
		begin
			p data
			if data[0]=='M'
				send_data @@reply
			else
				@@config['data'][data].each do |d|
					send_data d
				end
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

end


