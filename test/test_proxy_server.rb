#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test_helpper'
require 'proxy_server/proxy_server'
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
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start
      res=get('http://www.sogou.com/web?query=xxx', '127.0.0.1', 8078)
      assert_equal "200", res.code
      res=get('http://www.sogou.com/web?query=xxx', '127.0.0.1', 8078)
      assert_equal "200", res.code
      res=get('http://www.sogou.com/', '127.0.0.1', 8078)
      assert_equal "200", res.code
      server.stop
    end


    def test_two_server
      host1='www.baidu.com'
      config1={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => host1, "forward_port" => 80}
      server1=ProxyServer::ProxyServer.new config1

      host2='www.sogou.com'
      config2={"host" => '0.0.0.0', 'port' => 8079, 'forward_host' => host2, "forward_port" => 80}
      server2=ProxyServer::ProxyServer.new config2

      server1.start
      server2.start

      res=get("http://#{host1}/", '127.0.0.1', 8078)
      assert_equal "200", res.code
      res=get("http://#{host1}/", '127.0.0.1', 8078)
      assert_equal "200", res.code
      server1.stop

      res=get("http://#{host2}/", '127.0.0.1', 8079)
      assert_equal "200", res.code
      server2.stop
    end

    #can't work in jruby, would be block on the start_server
    def ttest_start_in_em
      host1='www.baidu.com'
      config1={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => host1, "forward_port" => 80}
      server1=ProxyServer::ProxyServer.new config1

      host2='www.sogou.com'
      config2={"host" => '0.0.0.0', 'port' => 8079, 'forward_host' => host2, "forward_port" => 80}
      server2=ProxyServer::ProxyServer.new config2

      Thread.new do
        EM.run do
          server1.start_in_em(true)
          server2.start_in_em(true)
        end
      end
=begin
      Thread.new do
        EM.run do
          server1.start
        end
      end

      Thread.new do
        EM.run do
          server2.start
        end
      end
=end
=begin
      server1.start
      server2.start
=end
=begin
      Thread.new do
        EM.run do
          server1.proxy=EventMachine::start_server(config1['host'], config1['port'],
                                                   EventMachine::ProxyServer::Connection, :debug => false) do |conn|
            server1.em_run=true
            server1.run conn
          end
        end
      end
      Thread.new do
        EM.run do
          server2.proxy=EventMachine::start_server(config2['host'], config2['port'],
                                                   EventMachine::ProxyServer::Connection, :debug => false) do |conn|
            server2.em_run=true
            server2.run conn
          end

        end
      end
=end

      res=get("http://#{host1}/", '127.0.0.1', 8078)
      assert_equal "200", res.code
      res=get("http://#{host1}/", '127.0.0.1', 8078)
      assert_equal "200", res.code
      server1.stop

      res=get("http://#{host2}/", '127.0.0.1', 8079)
      assert_equal "200", res.code


      server2.stop
    end

    def test_mock
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.baidu.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.mock do |req, res|
        res.data="HTTP/1.1 200 OK\r\nContent-Length:4\r\n\r\nmock"
      end
      server.start
      #p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
      res=get('http://www.baidu.com/', '127.0.0.1', 8078)
      assert_equal "200", res.code
      assert_equal 'mock', res.body
      server.stop
    end

    def test_post
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code
      server.stop
    end

    def test_post_mock
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.mock do |req, res|
        #替换响应的内容
        #jruby下会有异常，是这段代码导致的，以后需要增加线程安全锁, cruby不会有异常提示
        res.data.gsub!('seveniruby', 'rubyiseven')
      end
      server.start
      sleep 3
      uri = URI('http://127.0.0.1:8078/web')
      res=Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')
      assert_equal nil, res.body.index('seveniruby')
      #判断是否出现在响应中
      assert_equal true, res.body.index('rubyiseven')>20
      server.stop
    end

    def test_listen
      config={"host" => '0.0.0.0', 'port' => 8078}
      server=ProxyServer::ProxyServer.new config
      server.start
      require 'open-uri'
      res=open('http://127.0.0.1:8078/')
      assert_equal 'stub', res.read
      server.stop
      p "server2 stop"
    end

    def test_mock_listen
      config={"host" => '0.0.0.0', 'port' => 8078}
      server=ProxyServer::ProxyServer.new config
      server.mock do |req, res|
        res.data="HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\nxxxx"
      end
      server.start
      res=get('http://127.0.0.1:8078/')
      assert_equal 'xxxx', res.body
      server.stop
      p "server2 stop"

    end

    def test_record
      #stub=StubServer.new
      #stub.start
      #config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => '127.0.0.1', "forward_port" => 65530}

      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.record=true
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      assert_equal 3, server.testcases.count
    end


    def test_replay_request
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.record=true
      server.start(true)
      #幸好现在的网站都不检查host，后续做http的应用时，host需要修改
      #res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      #assert_equal '200', res.code
      #res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      #assert_equal '200', res.code
      #assert_equal 3, server.testcases.count


      uri = URI('http://127.0.0.1:8078/docs/about.htm')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code
      expect=server.testcase
      testcase=server.replay_request
      #用http协议不太合适，因为http协议有分包策略，所以同样的请求，得到的结果也可能是不同的，在协议应用方面，还需要做兼容改进
      index=0
      p testcase
      assert_equal expect[0][:res][1..-1].join, testcase[0][:res][1..-1].join

      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code

      expect=server.testcase
      testcase=server.replay_request
      #用http协议不太合适，因为http协议有分包策略，所以同样的请求，得到的结果也可能是不同的，在协议应用方面，还需要做兼容改进
      index=0
      #同样的查询得到的动态页面也是不一样，这个必须是fail
      assert_not_equal expect[0][:res][1..-1].join, testcase[0][:res][1..-1].join
      sleep 3
    end

    def test_multi_response
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.record=true
      server.start()

      uri = URI('http://127.0.0.1:8078/web')
      #幸好现在的网站都不检查host，后续做http的应用时，host需要修改
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      #分包的个数是动态变化的
      assert_equal true, server.testcase[0][:res].count>10
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      assert_equal true, server.testcase[0][:res].count>10
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      assert_equal 3, server.testcases.count
      assert_equal true, server.testcase[0][:res].count>10
    end
  end

end


