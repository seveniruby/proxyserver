require 'test/unit'
require 'ci/reporter/test_unit'
require 'ci/reporter/rake/minitest_loader'

class TestReplay < Test::Unit::TestCase
  def self.add_testcase(m, &block)
    m="test_#{m}"
    self.send(:define_method, m, &block)
  end

  def self.add_class(x)
    Object.const_set(x, Class.new(TestReplay))
  end
  #主动运行测试用例，不依赖自动执行
  def self.run
    Test::Unit::Runner.new.run()
  end
end