#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test_helpper'
require 'proxy_server/proxy_server'
require 'test/unit'

if __FILE__==$0 || $0=='<script>'
	class TestEM < Test::Unit::TestCase
		def test_connect
      EM.run do
        EM.connect('0.0.0.0', 8078, ProxyServer::ProxyClient) do  |client|
          client.send_data "GET / HTTP/1.1\r\nHost: www.soguo.com\r\n\r\n"
        end
      end
		end
	end
end
