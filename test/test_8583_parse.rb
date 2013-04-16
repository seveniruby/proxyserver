require 'rubygems'
require 'proxy_server'
require 'proxyserver/iso8583server'
require 'proxyserver/echo_stub_server'
require 'test/unit'
require 'iso8583'
require 'iso8583/berlin'

include ISO8583
#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
	class ISO8583Test < Test::Unit::TestCase
		def test_stub
			#创建stub服务模拟服务端
			stub=StubServer.new
			stub.start

			require 'socket'
			sock = TCPSocket.new('127.0.0.1', 65530)
			#sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)  
			p sock.write '123'
			p 'write'
			res=sock.readpartial(100000)
			p 'read'
			p res
			assert_equal '123', res

			sock.puts 'xxx'
			res=sock.gets
			assert_equal "xxx\n", res
			p 'puts gets check'

			stub.stop
		end
		def test_proxy
			#创建stub服务模拟服务端
			stub=StubServer.new
			stub.start

			#启动代理
			config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'127.0.0.1',"forward_port"=>65530}
			server=ISO8583Proxy.new config
			server.start

			#发送8583数据包
			mes     = BerlinMessage.new
			mes.mti = "Network Management Request Response Issuer Gateway or Acquirer Gateway" 
			mes[2]  = 12341234
			mes[3]  = 1111
			mes[4]  = 100
			mes[6]  = 101
			mes[7]  = "0808120000"
			mes[10] = 100
			mes[11] = 0
			mes[12] = "740808120000"
			mes[14] = "1010"
			mes[22] = "POSDATACODE"
			mes[23] = 0
			mes[24] = 1
			mes[25] = 90
			mes[26] = 4444
			mes[30] = 150
			mes[32] = 321321
			mes[35] = ";123123123=123?5"
			mes[37] = "123 123"
			mes[38] = "90"
			mes[39] = 90
			mes[41] = "TermLoc!"
			mes[42] = "ID Code!"
			mes[43] = "Card Acceptor Name Location"
			mes[49] = "840"
			mes[51] = 978
			mes[52] = "\x00\x01\x02\x03"
			mes[53] = "\x07\x06\x05\x04"
			mes[54] = "No additional amount"
			mes[55] = '\x07\x06\x05\x04'
			mes[56] = 88888888888
			mes[59] = "I'm you're private data, data for money..."
			mes[64] = "\xF0\xF0\xF0\xF0"

			require 'socket'
			sock = TCPSocket.new('127.0.0.1', 8078)
			sock.write mes.to_b
			res=sock.readpartial(mes.to_b.size)
			sock.close
			p res
			p mes.to_b
			assert_equal mes.to_b, res

			stub.stop
			p "stub stop"

			#must stop stub first, because there's a stop_event_loop in the server callback, so it should be stop at last
			server.stop
			p "server stop"

		end	
	end
end


