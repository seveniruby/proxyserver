require 'test/unit'
class TestReplay < Test::Unit::TestCase
  def self.add_testcase(m, &block)
    m="test_#{m}"
    self.send(:define_method, m, &block)
  end

  def self.add_class(x)
    Object.const_set(x, Class.new(TestReplay))
  end
end