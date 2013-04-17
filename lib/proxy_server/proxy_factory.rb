#encoding: utf-8
#
#
class Proxys
	def self.new(config)
    include ProxyServer::ProxyServer
		case config['protocol']
		when 'http'
			server=ProxyServer::HttpProxy.new config
		when 'form'
			server=ProxyServer::FormProxy.new config
		when 'mysql'
		when 'cache'
		end

		return server
	end

end
