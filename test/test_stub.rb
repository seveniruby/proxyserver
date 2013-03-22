$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test/unit'
require 'test_helpper'

if __FILE__==$0 || $0=='<script>'
	class TestStub < Test::Unit::TestCase
		def setup
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>{'hello'=>['word','boy']}}
			@stub=Stub.new 'stub',config
			@stub.start
		end
		def test_data
			client=TCPSocket.new('127.0.0.1', 65531)
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res
		end
		def test_mock
			@stub.mock do |req, res|
				p 'mock'
				res="xxxx" if req=='wwww'
				res
			end
			client=TCPSocket.new('127.0.0.1', 65531)
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res

			client.write 'wwww'
			res=client.readpartial(1000)
			assert_equal 'xxxx',res
		end

		def test_two_stub
			p EM.reactor_running?
			config={'host'=>'127.0.0.1', 'port'=>65530, 'data'=>{'hello'=>['word','boy']}}
			@stub2=Stub.new 'stub2', config
			@stub2.start

			p EM.reactor_running?
			config={'host'=>'127.0.0.1', 'port'=>65532, 'data'=>{'hello'=>['word','boy']}}
			@stub3=Stub.new 'stub3', config
			@stub3.start

			sleep 2

			client=TCPSocket.new('127.0.0.1', 65530)
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res

			client=TCPSocket.new('127.0.0.1', 65531)
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res
		end
		def test_one_stub
			p EM.reactor_running?
			config={'host'=>'127.0.0.1', 'port'=>65530, 'data'=>{'hello'=>['word','boy']}}
			@stub2=Stub.new 'stub2', config
			@stub2.start

			sleep 3

			client=TCPSocket.new('127.0.0.1', 65530)
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res
			client.write 'hello'
			res=client.readpartial(1000)
			assert_equal 'wordboy',res
			client2=TCPSocket.new('127.0.0.1', 65530)
			client2.write 'hello'
			res=client2.readpartial(1000)
			assert_equal 'wordboy',res
		end

		def teardowns
			@stub.stop
		end

	end
end
