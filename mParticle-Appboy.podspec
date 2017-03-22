Pod::Spec.new do |s|
    s.name             = "mParticle-Appboy"
    s.version          = "7.0.0-beta1"
    s.summary          = "Appboy integration for mParticle"

    s.description      = <<-DESC
                       This is the Appboy integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-appboy.git", :tag => s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticles"

    s.ios.deployment_target = "8.0"
    s.ios.source_files      = 'mParticle-Appboy/*.{h,m,mm}'
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 7.0.0-beta1'
    s.ios.frameworks = 'CoreTelephony', 'SystemConfiguration'
    s.libraries = 'z'
    s.ios.dependency 'Appboy-iOS-SDK', '2.27.0'

    s.ios.pod_target_xcconfig = {
        'LIBRARY_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/Appboy-iOS-SDK/**',
        'OTHER_LDFLAGS' => '$(inherited) -l"AppboyKitLibrary"'
    }

    # s.tvos.deployment_target = "9.0"
    # s.tvos.source_files      = 'mParticle-Appboy/*.{h,m,mm}'
    # s.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 6.12.3'
    # s.tvos.frameworks = 'SystemConfiguration'
    # s.tvos.dependency 'Appboy-tvOS-SDK', '2.24.3'
    #
    # s.tvos.pod_target_xcconfig = {
    #     'LIBRARY_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/Appboy-tvOS-SDK/**'
    # }
end
