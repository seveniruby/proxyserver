#encoding: utf-8
#这个文件只是为了验证eventmachine的机制，校验jruby和cruby下的不同，测试用，不需要纳入纳入测试用例体系
$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test_helpper'
require 'proxy_server/proxy_server'
require 'test/unit'

if __FILE__==$0 || $0=='<script>'
  class TestEM < Test::Unit::TestCase

    def test_fork
      #windows不支持，要支持跨平台的话，就只能公用同一个em了
      p fork do
        sleep 10000
      end
    end
    def test_connect
      EM.run do
        EM.connect('0.0.0.0', 8078, ProxyServer::ProxyClient) do |client|
          client.send_data "GET / HTTP/1.1\r\nHost: www.soguo.com\r\n\r\n"
        end
      end
    end

    def test_start()
      options={:debug => true}
      status=false
      server1=''
      server2=''
      server3=''
      server4=''
      server5=''
      server6=''

      Thread.new do
        EM.run do
          EM.add_periodic_timer(20) do
            p EM.threadpool
            p EM.threadpool_size
            p EM.reactor_thread
          end

          server1=EventMachine::start_server('127.0.0.1', 9001,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.baidu.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server1} start"
          server2=EventMachine::start_server('127.0.0.1', 9002,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.sogou.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server2} start"
          server3=EventMachine::start_server('127.0.0.1', 9003,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.ifeng.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server3} start"
          server4=EventMachine::start_server('127.0.0.1', 9004,
                                             EventMachine::ProxyServer::Connection, options)
          p "server #{server4} start"
          server5=EventMachine::start_server('127.0.0.1', 9005,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.google.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server5} start"
          server6=EventMachine::start_server('127.0.0.1', 9006,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.bannedbook.org', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end

          p "server #{server6} start"
          status=true
        end
      end
      while !status
        sleep 1
      end


      p 'em run'
      p EM.threadpool
      p EM.threadpool_size
      p EM.reactor_thread

      sleep 3
      p 'stop server'
      EM.close_connection server1, true
      EM.stop_server server1
      EM.close_connection server2, true
      EM.stop_server server2
      EM.close_connection server3, true
      EM.stop_server server3
      EM.close_connection server4, true
      EM.stop_server server4
      EM.close_connection server5, true
      EM.stop_server server5
      EM.close_connection server6, true
      EM.stop_server server6


      Thread.new do
        EM.run do
          EM.add_periodic_timer(20) do
            p EM.threadpool
            p EM.threadpool_size
            p EM.reactor_thread
          end

          server1=EventMachine::start_server('127.0.0.1', 9001,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.baidu.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server1} start"
          server2=EventMachine::start_server('127.0.0.1', 9002,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.sogou.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server2} start"
          server3=EventMachine::start_server('127.0.0.1', 9003,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.ifeng.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server3} start"
          server4=EventMachine::start_server('127.0.0.1', 9004,
                                             EventMachine::ProxyServer::Connection, options)
          p "server #{server4} start"
          server5=EventMachine::start_server('127.0.0.1', 9005,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.google.com', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end
          p "server #{server5} start"
          server6=EventMachine::start_server('127.0.0.1', 9006,
                                             EventMachine::ProxyServer::Connection, options) do |conn|
            conn.server :forward, :host => 'www.bannedbook.org', :port => 80
            conn.on_data do |raw_req|
              raw_req
            end
            conn.on_response do |backend, raw_res|
              raw_res
            end
          end

          p "server #{server6} start"
          status=true
        end
      end
      while !status
        sleep 1
      end


      sleep 3000
      p 'stop server'
      EM.close_connection server1, true
      EM.stop_server server1
      EM.close_connection server2, true
      EM.stop_server server2
      EM.close_connection server3, true
      EM.stop_server server3
      EM.close_connection server4, true
      EM.stop_server server4
      EM.close_connection server5, true
      EM.stop_server server5
      EM.close_connection server6, true
      EM.stop_server server6
    end
  end
end
