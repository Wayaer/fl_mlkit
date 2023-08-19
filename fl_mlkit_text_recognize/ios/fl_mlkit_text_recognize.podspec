#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fl_mlkit_text_recognize.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fl_mlkit_text_recognize'
  s.version          = '0.0.1'
  s.summary          = 'Google mlkit text recognize plugin, supports Android and IOS.'
  s.description      = <<-DESC
Google mlkit text recognize plugin, supports Android and IOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/*.swift'
  s.dependency 'Flutter'
  s.dependency 'fl_camera'
  s.dependency 'GoogleMLKit/TextRecognition'
  s.dependency 'GoogleMLKit/TextRecognitionChinese'
  s.dependency 'GoogleMLKit/TextRecognitionDevanagari'
  s.dependency 'GoogleMLKit/TextRecognitionJapanese'
  s.dependency 'GoogleMLKit/TextRecognitionKorean'
  s.static_framework = true
  s.platform = :ios, '11.0'
  s.ios.deployment_target = '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
