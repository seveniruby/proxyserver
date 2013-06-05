#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test_helpper'
require 'proxy_server/proxy_server'
require 'test/unit'
require 'tracer'
#Tracer.on

#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
  class TestProxy < MiniTest::Unit::TestCase
    def test_get
      get 'http://www.baidu.com'
    end

    def test_http
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

    def test_restart
      4.times do |i|
        host1='www.sogou.com'
        config1={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => host1, "forward_port" => 80}
        server1=ProxyServer::ProxyServer.new config1
        server1.start()
        5.times do |j|
          res=get("http://#{host1}/", '127.0.0.1', 8078)
          assert_equal "200", res.code
        end
        require 'tracer'
        #Tracer.on
        server1.stop
      end
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

    #jruby下会有异常，可能是并发引起的ClosedChannelException。但是不影响用例执行
    def test_post_mock
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.mock do |req, res|
        res.data=res.data.gsub('seveniruby', 'rubyiseven')
      end
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res=Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')
      #判断是否出现在响应中
      assert_equal "200", res.code
      assert_equal true, res.body.gsub('rubyiseven').count>10
      #因为分包策略，关键词有可能被隔断，所以不可能完全替换，除非用httpproxy
      assert_equal true, res.body.gsub('seveniruby').count<10
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

    end

    def test_testcase
      #stub=StubServer.new
      #stub.start
      #config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => '127.0.0.1', "forward_port" => 65530}

      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      testcases=[]
      server.start
      query(server)
      pp server.testcase
      assert_equal true, server.testcase.count>7
      assert_equal 19, server.testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count
      server.stop
    end


    def test_replay_static
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start()
      uri = URI('http://127.0.0.1:8078/docs/about.htm')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code
      expect=server.testcase
      server.replay_request
      #需要增加判断是否返回响应
      sleep 2
      testcase=server.testcase
      pp expect
      pp testcase
      p       expect.map{|tc| tc[:res]}.join
      p testcase.map{|tc| tc[:res]}.join
      assert_equal expect.map{|tc| tc[:res]}.join.split("\r\n\r\n")[1..-1], testcase.map{|tc| tc[:res]}.join.split("\r\n\r\n")[1..-1]
      server.stop
    end

    def test_replay_dynamic
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start()
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code

      expect=server.testcase
      server.replay_request

      p 'expect'
      pp expect
      sleep 2
      testcase=server.testcase
      p 'testcase'
      pp testcase
      assert_equal 9, testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count
      assert_equal expect.map{|tc| tc[:res]}.join.gsub('class="pt"').count, testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count
      server.stop
    end

    def test_replay_response


      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start()
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code

      expect=server.testcase
      server.replay_response

      p 'expect'
      pp expect
      sleep 2
      testcase=server.testcase
      p 'testcase'
      pp testcase
      assert_equal testcase.count, expect.count
      assert_equal expect.map{|tc| tc[:res]}.join, testcase.map{|tc| tc[:res]}.join
      assert_equal expect.map{|tc| tc[:res]}.join.gsub('class="pt"').count, testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count
      server.stop
    end

    def test_multi_response
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start()

      uri = URI('http://127.0.0.1:8078/web')
      #幸好现在的网站都不检查host，后续做http的应用时，host需要修改
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      assert_equal 10, server.testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count

      server.testcase=[]
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal 10, server.testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count
      assert_equal '200', res.code
      server.testcase=[]
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      assert_equal 10, server.testcase.map{|tc| tc[:res]}.join.gsub('class="pt"').count
      server.stop
    end

    def query(server)
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'valgrind -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')
      assert_equal '200', res.code

    end

    def test_start_after_start
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      server.stop

    end

    def start_sogou
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start
      server
    end

    def teardown
      EM.stop if EM.reactor_thread
      sleep 2
    end
  end


end


