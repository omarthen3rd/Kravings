# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Kraving' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Kraving

  pod 'SwiftyJSON'
  pod 'Alamofire', '~> 4.4'
  pod 'DeviceKit', '~> 1.0'
  pod 'Cosmos', '~> 11.0'
  pod 'PhoneNumberKit', '~> 1.3'
  pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git', :branch => 'wip/swift4'
  pod 'SimpleImageViewer', '~> 1.1.1'
  pod 'PullToDismiss', '~> 2.1'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
    end
  end
end
