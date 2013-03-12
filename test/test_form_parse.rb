#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'proxyserver/formserver'
require 'test/unit'
require 'net/http'
require 'uri'

#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
	class TestHttp < Test::Unit::TestCase
		def test_http
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
			server=HttpServer.new config
			server.start
			sleep 3

			uri = URI('http://www.sogou.com/web')
			res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
			p res.code
			server.stop
			p "server2 stop"
		end

		def test_hook
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
			server=HttpServer.new config
			server_2.on_data do |req,res|
				p req
				p res
			end
			server.start
			sleep 3
			p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
			p 'req ok'
			server.stop
			p "server2 stop"
		end

	end
end


