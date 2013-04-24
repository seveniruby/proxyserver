#!/usr/bin/env rake
require "bundler/gem_tasks"

task :default => [:test]

task :test_all do
  Dir["test/test_*.rb"].each do |f|
    p f
    ruby f
  end
end


task :test do
  Dir[
      "test/test_proxy_server.rb",
      "test/test_http_proxy.rb",
      "test/test_proxy_factory.rb"
  ].each do |f|
    p f
    ruby f
  end
end
