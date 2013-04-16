#encoding: utf-8
#
#
class Proxys
	def self.new(config)
    include ProxyServer
		case config['protocol']
		when 'http'
			server=HttpProxy.new config
		when 'form'
			server=FormProxy.new config
		when 'mysql'
		when 'cache'
		end

		return server
	end

end
