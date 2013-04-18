#encoding: utf-8
#
#
class Proxys
  def self.new(config)
    case config['protocol']
      when 'http'
        server=ProxyServer::HttpProxy.new config
      when 'form'
        server=ProxyServer::FormProxy.new config
      when 'mysql'
      when 'cache'
      when 'tcp'
        server=ProxyServer::ProxyServer.new config
    end

    return server
  end

end
