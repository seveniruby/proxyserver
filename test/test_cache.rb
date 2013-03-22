$:.unshift(File.dirname(__FILE__) + '/../test')

require 'test/unit'
require 'test_helpper'

if __FILE__==$0 || $0=='<script>'
	class TestCache < Test::Unit::TestCase
		def start(host,port=80)
			config={"host"=>'0.0.0.0','port'=>1080,'forward_host'=>host,"forward_port"=>port}
			@cache=CacheServer.new config
			@cache.start
		end
		def test_proxy
			start 'zhidao.baidu.com'
			#res=get('http://www.baidu.com/s?wd=seveniruby','127.0.0.1',1080)
			res=get('http://zhidao.baidu.com/question/533471125.html','127.0.0.1',1080)
			assert_equal true, res.body.index('zhidao')>0
			stop

		end

		def test_cache
			start 'www.sogou.com'
			res=get('http://www.sogou.com/web?query=seveniruby','127.0.0.1',1080)
			assert_equal true, res.body.index('seveniruby')>0
			#获得cache的请求和响应数据
			data=@cache.data
			stop

			#启动一个假的服务器，用之前录制的请求填充
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>data}
			stub=CacheStubServer.config(config)
			stub.start

			#使用假的服务
			start '127.0.0.1', 65531
			res_cache=get('http://www.sogou.com/web?query=seveniruby','127.0.0.1',1080)
			assert_equal true, res_cache.body.index('seveniruby')>0
			assert_equal res.body, res_cache.body
			stop

			#对cache做修改
			data_new={}
			data.each do |k,vv|
				nk=k.gsub('seveniruby', 'rubyiseven')
				data_new[nk]=[]
				vv.each do |v|
					#cache里面存储的是gzip编码，所以此处的修改无意义，ruby的http对象会自己解压缩数据，所以低级的cacheserver是无法修改高级协议的
					nv=v.gsub('seveniruby', 'rubyiseven')
					data_new[nk]<<nv
				end
			end
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>data_new}
			stub=CacheStubServer.config(config)
			stub.start
			start '127.0.0.1', 65531
			#让rubyiseven的搜索结果也对应seveniruby
			res_cache=get('http://www.sogou.com/web?query=rubyiseven','127.0.0.1',1080)
			assert_equal true, res_cache.body.index('seveniruby')>0
			stop
		end

		def test_mock
			start 'www.sogou.com'
			@index=0
			@cache.mock do |req, res|
				res[2]="x"  if @index!=0
				p res
				@index+=1
				res
			end
			res=get('http://www.sogou.com/web?query=seveniruby','127.0.0.1',1080)
			p res.body
			p 'send'
			assert_equal true, res.body.index('seveniruby')>0
			stop
		end

		def test_cache_stub_server
			stub=CacheStubServer.start
			config={'host'=>'127.0.0.1', 'port'=>65531, 'data'=>{'hello'=>['word','boy']}}
			stub.config config
			stub.start
			client=TCPSocket.new('127.0.0.1', 65531)
			client.write 'hello'
			res=client.readpartial(100)
			assert_equal 'wordboy',res


		end

		def stop
			@cache.stop
			@cache=nil
		end
	end
end
