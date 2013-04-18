$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'rubygems'
require 'proxy_server'
require 'uri'
require 'net/http'

def get(url, proxy_addr=nil, proxy_port=nil)
  uri = URI(url)
  res=nil
  Net::HTTP.new(uri.host, uri.port, proxy_addr, proxy_port).start { |http|
    # always proxy via your.proxy.addr:8080
    res=http.get("#{uri.path}?#{uri.query}")
  }
  res

end
