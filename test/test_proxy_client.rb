#encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test_helpper'
require 'proxy_server/proxy_server'
require 'test/unit'

#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
  class TestProxyClient < Test::Unit::TestCase
    def test_get
      get 'http://www.baidu.com'
    end

    def test_http
      EventMachine.run {
        EventMachine.connect 'www.sogou.com', 80, ProxyServer::ProxyClient do |conn|
          conn.on_res do |data|


          end
          #conn.send_data 'xxx'
          conn.send_data "GET / HTTP/1.1\r\nHost: www.sogou.com\r\n\r\n"
        end

      }

    end
  end
end


