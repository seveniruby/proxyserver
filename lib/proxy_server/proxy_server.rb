#encoding: utf-8
require 'rubygems'
require 'yaml'
require 'json'
require 'base64'
require 'proxy_server/stub_server'
require 'proxy_server/proxy_client'

#解决jruby下的一个bug
module EventMachine
  class Connection
    def close_connection after_writing = false
      EM.next_tick do
        EventMachine::close_connection @signature, after_writing
      end
    end
  end
end


module ProxyServer
#存放request和response的结构。data可人可读可写的数据，raw为真正在底层传输的数据
  class ProxyRequest
    attr_accessor :data
    attr_accessor :raw

    def initialize
      @data=''
      @raw=''
    end
  end

  class ProxyResponse
    attr_accessor :data
    attr_accessor :raw

    def initialize
      @data=''
      @raw=''
    end
  end


  class ProxyServer
    #config['host']  config['port'] config['forward_host'] config['forward_port']

    attr_accessor :em_run
    attr_accessor :server_run
    attr_accessor :proxy
    attr_accessor :record
    attr_accessor :testcase
    attr_accessor :testcases

    def initialize(config)
      @config=config
      @thread=nil
      @proxy=nil
      @stub=nil
      @mocks=[]
      @request=ProxyRequest.new
      @response=ProxyResponse.new
      @raw_req=nil
      @raw_res=nil
      @@em_run=false
      @testcase=[]
      @testcases=[]
      @record=false
      @record_mode=1


    end

    #解码二进制，返回可读数据
    def decode_request(req)
      req.data=req.raw
    end

    #解码二进制，返回可读数据
    def decode_response(res)
      res.data=res.raw
    end

    #可读数据组装为二进制
    def encode_request(req)
      req.raw=req.data
    end

    def encode_response(res)
      res.raw=res.data
    end


    def record_request(req)
      #录制模式为每个请求对应一个新用例，一个请求可以对应多个响应
      if @record_mode==1 && @record
        #保存之前的测试用例
        testcase_stop
        #清空数据，重新开始新的测试用例
        testcase_start
      end
      @testcase<<{:req => req.data}
    end

    def record_response(res)
      @testcase<<{:res => res.data}
    end

    #定义测试用例的开始标记
    def testcase_start
      @testcase=[]
      #先占位
      @testcases<<@testcase
    end

    #测试用例执行完成的标记
    def testcase_stop
      #重新确定最终值
      @testcases[-1]=@testcase.dup if @testcase!=[]
    end

    #传入一个request，返回一个response
    def send(req)
      res=ProxyResponse.new
      encode_request(req)
      client=TCPSocket.new(@config['host'], @config['port'])
      client.send req.raw, 0
      p 'read'

      #res.raw=client.read
      begin
        while buf=client.readpartial(1024)
          res.raw+=buf
        end
      rescue Exception => e
        p e.message
      end
      p res.raw
      client.close
      decode_response(res)
      res
    end

    #用于回放请求，做客户端
    def replay_request
      p 'replay'
      req=ProxyRequest.new
      expect=ProxyResponse.new
      res=ProxyResponse.new

      @testcases.each do |expect|
        p expect
        p expect.count
        EM.run do
          index=0
          EM.connect @config['host'], @config['port'], ProxyClient do |client|
            client.on_res do |data|
              p 'on_res'
              p data
              index+=1
              res.raw=data
              self.decode_response(res)
              self.record_response(res)
              #assert_equal expect[index][:req], res.data
              #已经没有待发送的请求时
              p index
              p expect.count
              if expect.count<=index
                p 'diff'
                p expect
                p @testcase
                EM.stop
              end
              #如果下一个是req，就发送，否则等待response，将来需要修改为循环以解决多个请求对应一个response的情况
              if expect[index+1][:req]
                index+=1
                req.data=expect[index][:req]
                record_request(req)
                encode_request(req)
                client.send_data req.raw
              end
            end
            req.data=expect[index][:req]
            record_request(req)
            encode_request(req)
            p 'send'
            p req.raw
            p client
            client.send_data req.raw
          end
        end
      end
    end

    #用于回放响应，做mock服务器
    def replay_response

    end

    #提供用户机制干预结果。
    #可参考测试用例中的mock方法
    def mock_process(req, res)
      @mocks.each do |m|
        m.call(req, res)
      end
    end

    def mock(&blk)
      @mocks<< blk
    end

    def run(conn)
      #始终以代理的方式运行，如果没有设置转发，就自己自我转发
      if @config['forward_host']
        conn.server :forward, :host => @config['forward_host'], :port => @config['forward_port']||80
      else
        #there's bug
        @stub=StubServer.new
        @stub.start
        conn.server :forward, :host => '127.0.0.1', :port => 65530
      end
      # modify / process request stream
      conn.on_data do |raw_req|
        @request.raw=raw_req
        self.decode_request(@request)
        self.record_request(@request) if @record
        self.encode_request(@request)
        #must return the raw data
        @request.raw
      end
      # modify / process response stream
      conn.on_response do |backend, raw_res|
        @response.raw=raw_res
        self.decode_response(@response)
        self.mock_process(@request, @response)
        self.record_response(@response) if @record
        self.encode_response(@response)

        #此处如果用于多转发时，需要增加多转发时候的请求销毁，暂未用到，所以保持现状
        #must return raw data
        @response.raw
      end

      # termination logic
      conn.on_finish do |backend, name|
        # terminate connection (in duplex mode, you can terminate when prod is done)
        # unbind if backend == :srv
      end
    end

    def start(debug=false)
      server=self
      #在后台启动，防止block进程
      Thread.new do
        begin
          EM.run do
            @proxy=EventMachine::start_server(@config['host'], @config['port'],
                                              EventMachine::ProxyServer::Connection, :debug => debug) do |conn|
              server.em_run=true
              server.run conn
            end
          end
        rescue Exception => e
          puts "ERROR__________________"
          puts e.message
          puts e.backtrace
        end
      end
      sleep 2
      puts "#{self} server start on port #{@config['port']}"


    end

    #用于在EM.run中，这样可以启动多个server，将来可以考虑与start方法合并
    #can't work in jruby
    def start_in_em(debug=false)
      server=self
      @proxy=EventMachine::start_server(@config['host'], @config['port'],
                                        EventMachine::ProxyServer::Connection, :debug => debug) do |conn|
        server.run conn
        server.em_run=true
      end
    end

    #停止服务运行
    def stop
      puts "Terminating ProxyServer"
      #jruby's bug stop_server would be stop em.run
      EventMachine.stop_server @proxy
      begin
        @thread.exit if @thread
      rescue
      end
      #EventMachine.stop_event_loop
      sleep 2
    end

    #保持服务运行
    def keep
      p @thread
      @thread.join
    end
  end
end



