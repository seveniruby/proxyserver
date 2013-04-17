require 'proxy_server'
require 'eventmachine'


module ProxyServer
  class ProxyClient < EventMachine::Connection
    def initialize
      @on_init_service=[]
      @on_res_service=[]
      @on_close_service=[]
      super
    end
    def post_init
      p 'post_init'
      @on_init_service.each do |s|
        s.call
      end
      #send_data "GET / HTTP/1.1\r\nHost: www.sogou.com\r\n\r\n"
    end
    def connection_completed
      p 'connect'
    end
    def unbind
      p 'close connect'
      @on_close_service.each do |s|
        s.call
      end
    end

    def receive_data(data)
      @on_res_service.each do |s|
        s.call data
      end
    end
    def on_init(&blk)
      @on_init_service<<blk
    end
    def on_res(&blk)
      @on_res_service<<blk
    end
    def on_close(&blk)
      @on_close_service<<blk
    end
    def replay(testcase)
      @testcase=[]
      expect=testcase
      index=0
      self.on_res do |data|

            if @testcase[index][:res]

            end
      end
      send_data expect[0][:req]
    end
  end
end

=begin
EventMachine.run {
  EventMachine.connect '127.0.0.1', 8081, Echo
}
=end