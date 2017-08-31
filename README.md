# XBaseSDK

[![CI Status](http://img.shields.io/travis/lhjzzu/XBaseSDK.svg?style=flat)](https://travis-ci.org/lhjzzu/XBaseSDK)
[![Version](https://img.shields.io/cocoapods/v/XBaseSDK.svg?style=flat)](http://cocoapods.org/pods/XBaseSDK)
[![License](https://img.shields.io/cocoapods/l/XBaseSDK.svg?style=flat)](http://cocoapods.org/pods/XBaseSDK)
[![Platform](https://img.shields.io/cocoapods/p/XBaseSDK.svg?style=flat)](http://cocoapods.org/pods/XBaseSDK)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

参考链接: http://www.cnblogs.com/brycezhang/p/4117180.html

1  pod lib create XBaseSDK (然后简单回答四个问题)
2  修改podspec文件的配置信息
Pod::Spec.new do |s|
  s.name             = "XBaseSDK"
  s.version          = "0.1.0"
  s.summary          = "A short description of XBaseSDK."
  s.description      = <<-DESC
                       DESC

  s.homepage         = "https://github.com/<GITHUB_USERNAME>/XBaseSDK"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "lhjzzu" => "1822657131@qq.com" }
//路径为XBaseSDK所在的路径 , tag值要与版本一致
  s.source           = { :git => "/Users/user/Desktop/XBaseSDK", :tag => '0.1.0' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true
//Classes文件夹下必须再建立一个文件夹，然后把资源文件放到新建的文件夹中
  s.source_files = 'Pod/Classes/**/*.{h,m}'
  s.resource_bundles = {
    'XBaseSDK' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/XFetchModel.h','Pod/Classes/**/XModuleInfo.h','Pod/Classes/**/XRegisterApp.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 2.6.0'
  s.dependency 'SDWebImage'
end
按照默认配置，类库的源文件将位于Pod/Classes文件夹下，资源文件位于Pod/Assets文件夹下，可以修改s.source_files和s.resource_bundles来更换存放目录。s.public_header_files用来指定头文
件的搜索位置。
文件结构:

3.进入Example文件夹，执行pod install --no-repo-update，让demo项目安装依赖项并更新配置。

4  添加资源，注意文件存放的位置在Pod/Classes目录下，跟podspec配置要一致。
运行Pod install，让demo程序加载新建的类。也许你已经发现了，只要新增加类/资源文件或依赖的三方库都需要重新运行Pod install来应用更新。

5  进入整个工程目录（XBaseSDK）下，然后提交源码，打tag值

- git add .
- git commit -m '0.1.0'
- git tag -a 0.1.0 -m '0.1.0'

6  执行pod lib lint XBaseSDK.podspec  --allow-warnings（忽略警告） --verbose（打印细节）来验证类库
7 执行sudo gem install cocoapods-packager安装插件
8 执行pod package XBaseSDK.podspec  --library  --force 进行打包

- 其中--library指定打包成.a文件，如果不带上将会打包成.framework文件。--force是指强制覆盖
- 一般而言，我们先打包成.framework文件，来看看文件结构是否正确。

注意：

- 打包好的包使用的时候，第三方依赖库所需的.framework要导入到工程中

    例如AFNetworking需要导入SystemConfiguration.framework，MobileCoreServices.framework，security.framework，SDWebImage需要导入ImageIO.framework
 如果打包使用类目文件，那么使用的时候要target->build settings->Linking->other Linker Flags 设置为-ObjC

## Requirements

## Installation

XBaseSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "XBaseSDK"
```

## Author

lhjzzu, 1822657131@qq.com

## License

XBaseSDK is available under the MIT license. See the LICENSE file for more info.
