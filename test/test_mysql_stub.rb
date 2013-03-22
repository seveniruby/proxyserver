$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test/unit'
require 'test_helpper'

if __FILE__==$0 || $0=='<script>'
	class TestMysqlStub < Test::Unit::TestCase
		def test_start
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>{'hello'=>['word','boy']}}
			stub=MysqlStub.new "stub", config
			stub.start
		end
		def test_mock
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>{'hello'=>['word','boy']}}
			stub=MysqlStub.new "stub", config
			stub.start
			sleep 5
			client=TCPSocket.new('127.0.0.1', 65531)
			p 'connect ok'
			logo=client.readpartial(1000)
			assert_equal 12, logo.index('-log')
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res
			client.close
			stub.stop
		end

		#test stub.update
		def test_update
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>{'hello'=>['word','boy']}}
			stub=MysqlStub.new "stub", config
			stub.start
			stub.stop
			data={ 'hello'=>['word','boy'], 'who'=>['me','brother']}
			stub.update data
			p 'updte'
			stub.start
			client=TCPSocket.new('127.0.0.1', 65531)
			logo=client.readpartial(1000)
			assert_equal 12, logo.index('-log')
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res
			client.write 'who'
			res=client.readpartial(1000)
			assert_equal 'mebrother',res

			client.write 'xxx'
			res=client.readpartial(1000)
			assert_equal 35,res.index('miss')
			client.close

			stub.stop
		end


	end
end
