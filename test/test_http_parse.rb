#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test_helpper'
require 'proxy_server/http_proxy'
require 'test/unit'


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
			server=ProxyServer::HttpProxy.new config
      server.record=true
			server.start
      #代理方式sogou会返回gzip
			res=get('http://www.sogou.com/web?query=xxx','127.0.0.1',8078)
      assert_equal '200', res.code

      #post方式会直接返回未压缩数据
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code
			server.stop
    end

    def test_gzip
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.baidu.com', "forward_port" => 80}
      server=ProxyServer::HttpProxy.new config
      server.record=true
      server.start
      res=get('http://www.baidu.com/', '127.0.0.1', 8078)
      assert_equal "200", res.code
    end
	end
end


