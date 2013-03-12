#encoding: utf-8
require 'rubygems'
require 'proxyserver'

#兼容jruby和warble
if __FILE__==$0 || $0=='<script>'
=begin
	config={"host"=>'0.0.0.0','port'=>8077,'forward_host'=>'www.baidu.com',"forward_port"=>80}
	server=ProxyServer.new config
	server.start	
	sleep 3
	p `curl -x 127.0.0.1:8077 http://www.baidu.com/ 2>&1`	
	server.stop
=end
	config={"host"=>'0.0.0.0','port'=>8078,'forward_host'=>'www.baidu.com',"forward_port"=>80}
	server_2=ProxyServer.new config
	server_2.start
	sleep 3
	p `curl -x 127.0.0.1:8078 http://www.baidu.com/ 2>&1`
	server_2.stop
	p "server2 stop"
	
end


