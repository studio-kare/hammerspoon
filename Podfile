# Uncomment this line to define a global platform for your project
platform :osx, '13.0'

inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

project 'Hammerspoon', 'Profile' => :debug

target 'Hammerspoon' do
pod 'CocoaLumberjack', '3.8.5'
pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.57.3'
pod 'Sparkle', '2.6.4', :configurations => ['Release']
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
   puts "Enabling assertions in #{target.name}"

   target.build_configurations.each do |config|
     config.build_settings['ENABLE_NS_ASSERTIONS'] = 'YES'
     if ['10.6', '10.7', '10.8', '10.9', '10.10', '10.11', '10.12', '10.13', '10.14', '10.15', '11.0', '11.1', '11.2', '11.3', '11.4', '11.5', '12.0'].include? config.build_settings['MACOSX_DEPLOYMENT_TARGET']
       config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
     end
   end

   puts "Removing hard-coded architecture in #{target.name}"
   target.build_configurations.each do |config|
     config.build_settings.delete 'ARCHS'
   end

   puts "Configuring Sentry"
   target.build_configurations.each do |config|
     if target.name == 'Sentry'
       config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'SENTRY_NO_UIKIT=1']
     end
   end
  end
end
