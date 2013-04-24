#encoding: utf-8
require 'rubygems'
require 'yaml'
require 'json'
require 'base64'
require 'proxy_server/stub_server'
require 'proxy_server/proxy_client'
require 'test/unit'
require 'test/unit/assertions'

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
    attr_accessor :testcase
    attr_accessor :testcases
    attr_accessor :info

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
      @testcase_service=[]
      #@testcases=[]
      @testcase_mode=1
      @info=''
      @testcase_start_tag=false

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


    def save_request(req)
      #录制模式为每个请求对应一个新用例，一个请求可以对应多个响应
      if @testcase_mode==1 && @testcase_start_tag==false
        #清空数据，重新开始新的测试用例
        testcase_stop
        testcase_start
        @testcase_start_tag=false
      end
      @testcase<<{:req => req.data}
    end

    def save_response(res)
      #@testcase<<{:res => res.data}
      #使用更好的结构来保存数据
      #多次的响应被合并到:res
      #:req=>xxx, :res=xxx
      @testcase[-1][:res]||=''
      @testcase[-1][:res]<<res.data
    end

    #定义测试用例的开始标记
    #用于用户在外部标记自己的测试用例范围
    def testcase_start
      @testcase=[]
      @testcase_start_tag=true
      #先占位
      #暂时去掉这个功能，让外部用户来控制如何存储每个测试用例的数据
      #@testcases<<@testcase
    end

    #测试用例执行完成的标记
    def testcase_stop
      @testcase_start_tag=false
      #重新确定最终值
      return if @testcase==[]
      @testcase_service.each do |s|
        s.call(@testcase)
      end
=begin
if @testcases!=[]
      if @testcase!=[]
        @testcases[-1]=@testcase.dup
      end
      #end
=end
    end

    def tc(&blk)
      @testcase_service||=[]
      @testcase_service<<blk
    end

    #用于回放请求，做客户端，使用em进行回放
    def replay_request(testcase=nil)
      testcase||=@testcase
      req=ProxyRequest.new
      expect=ProxyResponse.new
      res=ProxyResponse.new

      #clear testcases for record new data
      #testcases_old=@testcases
      #@testcases=[]
      @testcase=[]
      unbind=false
      begin
        EM.run do
          index=0
          #in windows, connect 0.0.0.0 would fail , windows only understand  127.0.0.1
          EM.connect '127.0.0.1', @config['port'], ProxyClient do |client|
            client.on_res do
              unbind=true
            end
            testcase.each do |tc|
              req.data=tc[:req]
              encode_request(req)
              #client.send_data "GET / HTTP/1.1\r\nHost: www.sogou.com\r\n\r\n"
              client.send_data req.raw
            end
          end
          while !unbind
            sleep 2
          end
        end
      rescue Exception => e
        p "ERROR++++++++++++"
        p e.message
        raise
      end
      @testcase
    end

    #用于回放响应，做mock服务器
    def replay_response

    end

    #用于自动生成测试用例的回放形式
    def replay_testcase(testcase=nil)
      testcase||=@testcase

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

    def send(data)
      @conn.send_data data
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
        self.save_request(@request)
        self.encode_request(@request)
        #must return the raw data
        @request.raw
      end
      # modify / process response stream
      conn.on_response do |backend, raw_res|
        @response.raw=raw_res
        self.decode_response(@response)
        self.mock_process(@request, @response)
        self.save_response(@response)
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

    #jruby+thread+timer导致异常捕获困难，所以写了很多的异常捕获
    def start(options={})
      boot=false
      if  !EM.reactor_thread
        p 'start EM'
        begin
          @thread=Thread.new do
            begin
              EM.run do
                EM.add_timer(1) { boot=true }
                #jruby's bug jruby和cruby下的eventmachine存在行为不一致。在jruby下需要增加这个定时器才能让em不阻塞
                EM.add_periodic_timer(1) {}
              end
            rescue Exception => e
              if e.inspect.index('CancelledKeyException')!=nil || e.inspect.index('ClosedChannelException')!=nil
              else
                puts "ERROR_EM_RUN______________"
                puts e.message
                puts e.inspect
                p @info
                @info=e.message
                boot=nil
                raise
              end
            end

          end
        rescue Exception => e
          if e.inspect.index('CancelledKeyException')!=nil || e.inspect.index('ClosedChannelException')!=nil
          else
            puts "ERROR_THREAD______________"
            puts e.message
            puts e.inspect
            @info=e.message
            puts e.backtrace
            boot=nil
            #raise
          end
        end
        while boot==false
          sleep 1
        end
      end

      p 'Start Server'
      boot=false
      require 'tracer'
      begin
        EM.add_timer(1) do
          begin
            @proxy=EM::start_server(@config['host'], @config['port'],
                                    EM::ProxyServer::Connection, options) do |conn|
              self.em_run=true
              self.run conn
            end
            boot=true
          rescue Exception => e
            if e.inspect.index('CancelledKeyException')!=nil || e.inspect.index('ClosedChannelException')!=nil
            else
              puts "ERROR_Start_Server______________"
              puts e.message
              puts e.inspect
              @info=e.message
              boot=nil
              #raise
            end
          end

        end
      rescue Exception => e
        if e.inspect.index('CancelledKeyException')!=nil || e.inspect.index('ClosedChannelException')!=nil
        else
          puts "ERROR_EM_ADDTIMER______________"
          puts e.message
          puts e.inspect
          @info=e.message
          boot=nil
          #raise
        end
      end

      sleep 2
      while boot==false
        sleep 1
      end
      if boot==true
        @info="#{self} server start on port #{@config['port']}"
      end
      puts @info
    end

    #停止服务运行
    def stop
      @info="Terminating ProxyServer"
      begin

        #jruby's bug stop_server would be stop em.run
        EM.close_connection @proxy, true if @proxy
        EM.stop_server @proxy if @proxy
      rescue Exception => e
        if e.inspect.index('CancelledKeyException')!=nil || e.inspect.index('ClosedChannelException')!=nil
        else
          puts "ERROR_STOP______________"
          puts e.message
          puts e.inspect
          @info=e.message
          boot=nil
          #raise
        end
      end
      #@thread.kill if @thread
      #EventMachine.stop_event_loop
      @proxy=nil
      puts @info
    end

    #保持服务运行
    def keep
      p @thread
      @thread.join
    end
  end
end



