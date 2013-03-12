#encoding: utf-8
require 'rubygems'
require 'proxyserver'
require 'proxyserver/testserver'

#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
	config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
	server=TestServer.new config
=begin
	server_2.on_data do |req,res|
		p req
		p res
	end
=end
	server.start
	sleep 3
	p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
	p 'req ok'
	server.stop
	p "server2 stop"
	
end


