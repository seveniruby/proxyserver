require 'test/unit'
require 'proxyserver/stub_server'

if __FILE__==$0 || $0=='<script>'
	class TestStub < Test::Unit::TestCase
		def test_stub
			server=StubServer.new
			server.start
			server.stop
		end

		def test_res
			require 'open-uri'
			server=StubServer.new
			server.start
			res=open('http://127.0.0.1:65530/')
			assert_equal 'stub',res.read
			server.stop
		end

		def test_two_stub
			server=StubServer.new
			server2=StubServer.new 8077
			server.start
			server2.start
			server.stop
			server2.stop
		end
	end
end
