

Pod::Spec.new do |s|
  s.name             = "XBaseSDK"
  s.version          = "0.1.0"
  s.summary          = "this is base sdk." 
  s.description      = <<-DESC
                       this is base sdk.
                       DESC

  s.homepage         = "https://github.com/<GITHUB_USERNAME>/XBaseSDK"
  s.license          = 'MIT'
  s.author           = { "lhjzzu" => "1822657131@qq.com" }
  s.source           = { :git => "/Users/chiyou/Desktop/XBaseSDK", :tag => '0.1.0' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*.{h,m}'
#s.resource_bundles = {
#   'XBaseSDK' => ['Pod/Assets/*.png']
# }

  s.public_header_files = 'Pod/Classes/**/XFetchModel.h','Pod/Classes/**/XModuleInfo.h','Pod/Classes/**/XRegisterApp.h','Pod/Classes/**/XLibManager.h','Pod/Classes/**/XTool.h'
   s.dependency 'AFNetworking', '~> 2.3'
   s.dependency 'SDWebImage'
end
