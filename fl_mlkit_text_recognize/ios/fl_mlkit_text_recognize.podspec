Pod::Spec.new do |s|
  s.name             = 'fl_mlkit_text_recognize'
  s.version          = '4.0.0'
  s.summary          = 'Google ML Kit text recognition plugin, supports Android and iOS.'
  s.description      = <<-DESC
Google ML Kit text recognition plugin for Flutter.
Supports Latin, Chinese, Japanese, Korean and Devanagari.
                       DESC
  s.homepage         = 'https://github.com/Wayaer/fl_mlkit/tree/main/fl_mlkit_text_recognize'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Wayaer' => 'https://github.com/Wayaer' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.resource_bundles = { 'fl_mlkit_text_recognize_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.dependency 'fl_camera'
  s.dependency 'fl_channel'
  s.dependency 'GoogleMLKit/TextRecognition'
  s.dependency 'GoogleMLKit/TextRecognitionChinese'
  s.dependency 'GoogleMLKit/TextRecognitionDevanagari'
  s.dependency 'GoogleMLKit/TextRecognitionJapanese'
  s.dependency 'GoogleMLKit/TextRecognitionKorean'
  s.static_framework = true
  s.ios.deployment_target = '15.5'
  s.pod_target_xcconfig  = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
