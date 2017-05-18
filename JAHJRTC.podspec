Pod::Spec.new do |s|
  s.name             = 'JAHJRTC'
  s.version          = '0.1.0'
  s.summary          = 'Conversion between Jingle XML and SDP'

  s.homepage         = 'https://github.com/hjon/JAHJRTC'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Jon Hjelle'
  s.social_media_url = 'https://twitter.com/hjon'

  s.source           = { :git => 'https://github.com/hjon/JAHJRTC.git', :tag => s.version.to_s }
  s.source_files = 'JAHJRTC/Classes/**/*'

  s.ios.deployment_target = '8.0'

  s.dependency 'KissXML'
end
