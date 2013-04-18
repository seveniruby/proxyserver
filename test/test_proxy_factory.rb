#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')


require 'test_helpper'
require 'proxy_server'
require 'test/unit'


#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
	class TestFactory < Test::Unit::TestCase
		def setup
			@port=8081
		end
		def test_http
			http=Proxys.new 'protocol'=>'http', 'forward_host'=>'www.baidu.com', 'forward_port'=>80, 'port'=>@port, 'host'=>'127.0.0.1'
			http.start
			get 'http://www.baidu.com/','127.0.0.1',@port
    end
    def test_tcp
      http=Proxys.new 'protocol'=>'tcp', 'forward_host'=>'www.baidu.com', 'forward_port'=>80, 'port'=>@port, 'host'=>'127.0.0.1'
      http.start
      get 'http://www.baidu.com/','127.0.0.1',@port
    end

		def test_form
			http=Proxys.new 'protocol'=>'form', 'forward_host'=>'www.sogou.com', 'forward_port'=>80, 'port'=>@port, 'host'=>'127.0.0.1'
			http.start
			p 'no query'
			get "http://127.0.0.1:#{@port}"
			p 'query'
			get "http://127.0.0.1:#{@port}/web?query=systemtap"
			http.stop


		end
		

		def test_http_mock
			http=Proxys.new 'protocol'=>'http', 'forward_host'=>'www.baidu.com', 'forward_port'=>80, 'port'=>@port, 'host'=>'127.0.0.1'
			http.mock do |req, res|
				p req.size
				p res.size
				res
			end
			http.start
			get 'http://www.baidu.com/','127.0.0.1',@port
			http.stop
		end
	end
end
