Pod::Spec.new do |s|
    s.name             = "mParticle-Appboy"
    s.version          = "8.2.3"
    s.summary          = "Appboy integration for mParticle"

    s.description      = <<-DESC
                       This is the Appboy integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-appboy.git", :tag => s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"
    s.static_framework = true
    s.swift_version = '5.3'

    s.ios.deployment_target = "11.0"
    s.ios.source_files      = 'Sources/**/*.{h,m,mm}'
    s.ios.dependency 'mParticle-Apple-SDK', '~> 8.0'
    s.ios.dependency 'BrazeKit', '~> 6.1'
    s.ios.dependency 'BrazeKitCompat', '~> 6.1'
    s.ios.dependency 'BrazeUI', '~> 6.1'
    
    s.tvos.deployment_target = "11.0"
    s.tvos.source_files      = 'Sources/**/*.{h,m,mm}'
    s.tvos.dependency 'mParticle-Apple-SDK', '~> 8.0'
    s.tvos.dependency 'BrazeKit', '~> 6.1'
    s.tvos.dependency 'BrazeKitCompat', '~> 6.1'


end
