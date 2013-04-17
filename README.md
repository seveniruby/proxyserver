# Proxyserver

replay的目标
1. 流量录制与重放
2. 流量转化为测试用例
3. 可以根据录制数据自动进行mock
4. 支持协议扩展，从而应用于其他的网络协议甚至是文件句柄

replay的用途
1. diff测试
2. 回归测试
3. 接口自动化
4. 将来的白盒分析与测试建模，这方面的构想较多，暂不铺展了，如果你在testcircle群， 我想你会懂的


replay项目创建的原因

百度有个不错的框架supertest
可惜是年久失修架构臃肿，不支持跨平台也不能方便的做上层的二次开发，开源也block了。
其他失修的原因也很多，总之就是一个优秀的框架被埋没了。
我本来想改进它，但是后来预测会离职，所以就放弃重修重启一个新的项目replay。
replay的思想是loadrunner的模式，希望可以把接口测试做的更彻底开放，我有很多的想法想应用于接口测试中。
做一套接口测试框架，也是我在阿里，百度时一个未了的心愿。在此实现它，我也会持续改进

## Installation

Add this line to your application's Gemfile:

    gem 'proxyserver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install proxyserver

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
