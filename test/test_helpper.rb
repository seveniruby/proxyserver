$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'rubygems'
require 'proxyserver'
require 'uri'
require 'net/http'

def get(url,proxy_addr=nil, proxy_port=nil)
	uri = URI(url)
	res=nil
	if proxy_addr
		Net::HTTP.new(uri.host, uri.port, proxy_addr, proxy_port).start { |http|
			# always proxy via your.proxy.addr:8080
			res=http.get("#{uri.path}?#{uri.query}")
		}
	else
		res=Net::HTTP.get(uri) # => String
	end
	res

end
