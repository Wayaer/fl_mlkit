Pod::Spec.new do |s|
  s.name             = 'fl_mlkit_translate_text'
  s.version          = '2.0.0'
  s.summary          = 'Google ML Kit on-device text translation plugin, supports Android and iOS.'
  s.description      = <<-DESC
Google ML Kit on-device text translation plugin for Flutter.
Supports Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_translate_text'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Wayaer' => 'https://github.com/Wayaer' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.resource_bundles = { 'fl_mlkit_translate_text_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.dependency 'GoogleMLKit/Translate'
  s.static_framework = true
  s.ios.deployment_target = '15.5'
  s.pod_target_xcconfig  = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
