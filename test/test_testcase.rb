$:.unshift(File.dirname(__FILE__) + '/../test')
require 'test_helpper'
require 'proxy_server'
require 'test/unit'
require 'ci/reporter/test_unit'
require 'ci/reporter/rake/minitest_loader'

def test_add_class
  TestReplay.add_class 'TestABC'
  TestReplay.add_class 'TestCDE'
  10.times do |i|
    TestABC.add_testcase(i) do
      assert_equal 2, 2
    end
  end

  10.times do |i|
    TestCDE.add_testcase(i) do
      assert_equal 2, 2
    end
  end

end

def test_server

  config={"host" => '0.0.0.0', 'port' => 8078, 'forward_host' => 'www.sogou.com', "forward_port" => 80}
  server=ProxyServer::ProxyServer.new config
  testcases=[]
  server.testcase_callback do |testcase|
    testcases<<testcase
  end
  server.start()
  uri = URI('http://127.0.0.1:8078/web')
  res = Net::HTTP.post_form(uri, 'q' => 'systemtap', 'query' => 'systemtap -english')
  res = Net::HTTP.post_form(uri, 'q' => 'valgrind', 'query' => 'valgrind -english')
  res = Net::HTTP.post_form(uri, 'q' => 'seveniruby', 'query' => 'seveniruby -english')

  server.testcase_stop
  p testcases


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
    index+=1
  end
  TestReplay.run
end


#test_server
test_add_class
p 'testcase run ok'