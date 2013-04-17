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
        res.data.gsub!('seveniruby', 'rubyiseven')
      end
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res=Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')
      p res.body.index('seveniruby')
      p res.body.index('rubyiseven')
      assert_equal nil, res.body.index('seveniruby')
      assert_equal true, res.body.index('rubyiseven')>0
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
      server.start()
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code

      #res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      #assert_equal '200', res.code
      #res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      #assert_equal '200', res.code
      #assert_equal 3, server.testcases.count

      expect=server.testcase
      testcase=server.replay_request
      p expect
      p testcase
      assert_equal expect, testcase

      sleep 3
    end
  end
end


