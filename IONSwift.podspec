Pod::Spec.new do |s|
  s.name               = 'IONSwift'
  s.version            = '0.0.1'
  s.summary            = 'Intelligent Open Network. Swift framework'
  s.homepage           = 'https://github.com/kxpone/ion-swift'
  s.license            = 'MIT'
  s.author             = { 'Software Engineer' => 'ivanmanov@live.com' }
  s.social_media_url   = 'https://twitter.com/ihellc'

  s.requires_arc           = false
  s.ios.deployment_target  = '13.0'
  s.tvos.deployment_target = '13.0'
  s.osx.deployment_target  = '10.15'

  s.source             = { :git => 'https://github.com/kxpone/ion-swift/ion-swift.git', :tag => s.version }

  s.default_subspec    = 'AllModules'
  
  s.subspec 'Core' do |c|
    c.source_files     = 'Framework/ion-swift/Core/**/*.swift'
  end
  
  s.subspec 'IONModule' do |ionm|
    ionm.source_files  = 'Framework/ion-swift/Modules/IONModule/**/*.swift'
    ionm.dependency    'IONSwift/Core'
  end
  
  s.subspec 'AllModules' do |am|
    am.dependency      'IONSwift/IONModule'
  end

end
