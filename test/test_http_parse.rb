#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'proxyserver/http_proxy'
require 'test/unit'
require 'test_helpper'

#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
	class TestHttp < Test::Unit::TestCase
		def test_get
			get 'http://www.baidu.com'
		end
		def test_http
      #require 'tracer'
      #Tracer.on
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.sogou.com',"forward_port"=>80}
			server=HttpProxy.new config
			server.start
			res=get('http://www.sogou.com/web?query=xxx','127.0.0.1',8078)
      #res=get('http://www.sogou.com/web?query=xxx','127.0.0.1',8078)
      #res=get('http://www.sogou.com/','127.0.0.1',8078)
			server.stop
		end

		def test_two_server
      host='www.baidu.com'
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>host, "forward_port"=>80}
			server=HttpProxy.new config
			server.start
			#p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
			get "http:/#{host}", '127.0.0.1',8078
			p 'req ok'
			server.stop
			p "server1 stop"

			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
			server=HttpProxy.new config
			p 'server2 start'
			server.start
			#p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
			get 'http://www.baidu.com/','127.0.0.1',8078
			p 'req ok'
			server.stop
			p "server2 stop"
		end

		def ttest_hook
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
			server=HttpProxy.new config
			server.on_data do |req,res|
				p req
				p res
			end
			server.start
			sleep 3
			#p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
			get 'http://www.baidu.com/','127.0.0.1',8078
			p 'req ok'
			server.stop
		end

		def test_post
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
			server=HttpProxy.new config
			server.start
			uri = URI('http://www.sogou.com/web')
			res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
			assert_equal '200', res.code
			server.stop
		end

		def ttest_post_hook
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
			server=HttpProxy.new config
			server.mock do |req,res|

			end
			server.start
			uri = URI('http://www.sogou.com/web')
			res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
			p res.code
			server.stop
		end

		def test_listen
			config={"host"=>'0.0.0.0','port'=>8078}
			server=HttpProxy.new config
			server.start
			require 'open-uri'
			res=open('http://127.0.0.1:8078/')
			assert_equal 'stub',res.read
			server.stop
			p "server2 stop"

		end

		def test_mock_listen
			config={"host"=>'0.0.0.0','port'=>8078}
			server=HttpProxy.new config
			server.mock do |req|
				p "user"
				res="HTTP/1.1 200 OK\nContent-Length: 4\n\nxxxx"
				p res
				res
			end
			server.start
			res=get('http://127.0.0.1:8078/')
			assert_equal 'xxxx',res
			server.stop
			p "server2 stop"

		end


	end
end


