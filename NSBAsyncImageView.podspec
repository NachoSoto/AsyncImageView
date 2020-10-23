Pod::Spec.new do |s|
  s.name             = 'NSBAsyncImageView'
  s.version          = '7.1'
  s.summary          = 'UIImageView for rendering data asynchronously, with composable renderers and caches'
  s.description      = 'This is a Swift framework that provides an easy to use UIImageView subclass for effectively loading and rendering images asynchronously, providing caching, and error handling.'

  s.homepage         = 'https://github.com/NachoSoto/AsyncImageView'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Ignacio Soto' => 'hello@nachosoto.com' }
  s.source           = { :git => 'https://github.com/NachoSoto/AsyncImageView.git', :tag => s.version.to_s }
  s.ios.deployment_target = "13.0"
  s.tvos.deployment_target = "13.0"

  s.source_files  = "AsyncImageView/*.{swift}", "AsyncImageView/Renderers/*.{swift}"
  s.module_name = 'AsyncImageView'
  
  s.dependency 'ReactiveSwift', '~> 6.1'
  s.swift_version = '5.0'
end
