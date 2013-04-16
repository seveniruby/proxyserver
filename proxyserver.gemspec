# -*- encoding: utf-8 -*-
require File.expand_path('../lib/proxyserver/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["seveniruby"]
  gem.email         = ["seveniruby@gmail.com"]
  gem.description   = %q{mock server}
  gem.summary       = %q{mock server}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "proxy_server"
  gem.require_paths = ["lib"]
  gem.version       = Proxyserver::VERSION
end
