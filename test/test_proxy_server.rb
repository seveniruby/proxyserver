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

    def test_start
      require 'tracer'
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server_1 = ProxyServer::ProxyServer.new config
      server_1.start
      #server_1.stop
      p 'start same server on same port'
      server=ProxyServer::ProxyServer.new config
      server.start
      assert_equal "unable to open socket acceptor: java.net.BindException: Address already in use: bind", server.info
      server_1.stop
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

    def test_save
      #stub=StubServer.new
      #stub.start
      #config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => '127.0.0.1', "forward_port" => 65530}

      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config

      testcases=[]
      server.tc do |testcase|
        testcases<<testcase
      end
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      server.testcase_stop
      assert_equal 3, testcases.count
      server.stop
    end


    def test_replay_request
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      server.start()
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
      #http协议有分包策略，所以同样的请求，得到的结果也可能是不同的，在协议应用方面，还需要做兼容改进
      index=0
      assert_equal expect[0][:res].split("\r\n\r\n")[1..-1], testcase[0][:res].split("\r\n\r\n")[1..-1]

      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'query' => 'ruby -english')
      assert_equal '200', res.code

      expect=server.testcase
      testcase=server.replay_request
      #同样的查询得到的动态页面也是不一样，这个必须是fail
      assert_not_equal expect[0][:res], testcase[0][:res]
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
      assert_equal 10, server.testcase[0][:res].gsub('class="pt"').count
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal 10, server.testcase[0][:res].gsub('class="pt"').count
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      assert_equal 10, server.testcase[0][:res].gsub('class="pt"').count
      server.stop
    end

    def test_testcase
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      testcases=[]
      server.tc do |testcase|
        testcases<<testcase
      end
      server.start()
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'valgrind -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')
      assert_equal '200', res.code
      server.testcase_stop
      assert_equal 3, testcases.count

      testcases.each do |expect|
        testcase=server.replay_request(expect)
        #返回的首页结果应该都是10
        expect_count=expect[0][:res].gsub('class="pt"').count
        res_count=testcase[0][:res].gsub('class="pt"').count
        #结果应该不同，因为有动态内容
        assert_not_equal expect, testcase
        assert_equal expect_count, res_count
      end

      TestReplay.add_class("TestXXX")
      index=0
      testcases.each do |expect|
        TestReplay.add_testcase(index) do
          testcase=server.replay_request(expect)
          #返回的首页结果应该都是10
          expect_count=expect[0][:res].gsub('class="pt"').count
          res_count=testcase[0][:res].gsub('class="pt"').count
          #结果应该不同，因为有动态内容
          assert_not_equal expect, testcase
          assert_equal expect_count, res_count
        end
      end
      server.stop


    end

    def test_add_testcase
      config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
      server=ProxyServer::ProxyServer.new config
      testcases=[]
      server.tc do |testcase|
        testcases<<testcase
      end
      server.start()
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'valgrind -english')
      assert_equal '200', res.code
      res = Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')
      assert_equal '200', res.code
      server.testcase_stop
      assert_equal 3, testcases.count

      index=0

      #增加测试用例集
      TestReplay.add_class("TestCount")
      testcases.each do |expect|
        #增加测试集中的测试用例
        TestCount.add_testcase(index) do
          testcase=server.replay_request(expect)
          #返回的首页结果应该都是10
          expect_count=expect[0][:res].gsub('class="pt"').count
          res_count=testcase[0][:res].gsub('class="pt"').count
          #结果应该不同，因为有动态内容
          assert_not_equal expect, testcase
          assert_equal expect_count, res_count
        end
      end
      server.stop
      #can't run testcase in testcase, you can see the test_testcase.rb for example
      #TestReplay.run

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

    def test_testcase_start
      server=start_sogou
      testcases=[]
      server.tc do |testcase|
        testcases<< testcase
      end
      server.testcase_start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code

      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      server.testcase_stop
      assert_equal 1, testcases.count
      assert_equal 2, server.testcase.count
      server.stop

      testcases=[]
      server.start
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      uri = URI('http://127.0.0.1:8078/web')
      res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
      assert_equal '200', res.code
      server.stop
      assert_equal 1, testcases.count


    end

    def setup
      sleep 1
    end

    def teardown
      EM.stop
    end
  end


end


