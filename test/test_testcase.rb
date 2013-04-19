$:.unshift(File.dirname(__FILE__) + '/../test')
require 'test_helpper'
require 'proxy_server'
require 'test/unit'


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