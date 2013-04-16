$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'proxy_server'
require 'proxy_server/cacheserver'

if __FILE__==$0 || $0=='<script>'
	#mysql主机  真实代理  cache代理
	#mysqlcache 1.2.3.4 3306 1080 1081
	
	puts "example:
	cache target_host:target_port  target_proxy_port cache_host:cache_port
	cache www.sogou.com:80 1080 127.0.0.1:65531
	"
	target_host, target_port=ARGV[0].split(':')
	target_proxy_port=ARGV[1] || 7000
	cache_host, cache_port=ARGV[2].split(':')
	#cache_proxy_port=ARGV[3] || 7001

	p "target_host= #{target_host}"
	p "target_port= #{target_port}"
	p "target_proxy_port= #{target_proxy_port}"
	p "cache_host= #{cache_host}"
	p "cache_port= #{cache_port}"
	#p "cache_proxy_port= #{cache_proxy_port}"

	

	#启动一个cache服务器，用代理录制的请求填充
	config={'host'=>cache_host, 'port'=>cache_port.to_i, 'data'=>{}}
	@stub=CacheStubServer.config(config)
	@stub.start

=begin
	#代理访问cache server
	config={"host"=>'0.0.0.0','port'=>cache_proxy_port.to_i, 'forward_host'=>cache_host, "forward_port"=>cache_port.to_i}
	@cache=CacheServer.new config
	@cache.start
=end
	config={"host"=>'0.0.0.0','port'=>target_proxy_port.to_i, 'forward_host'=>target_host, "forward_port"=>target_port.to_i}
	@sogou=CacheServer.new config
	@sogou.callback do 
		@stub.update @sogou.data
	end
	@sogou.start

	
	
	
	p "OK"

	while true do 
		sleep 1000
	end

end
