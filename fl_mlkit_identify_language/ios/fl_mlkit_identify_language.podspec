#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fl_mlkit_identify_language.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fl_mlkit_identify_language'
  s.version          = '0.0.1'
  s.summary          = 'Identify the language of text with ML Kit on Android And IOS'
  s.description      = <<-DESC
Identify the language of text with ML Kit on Android And IOS
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GoogleMLKit/LanguageID'
  s.static_framework = true
  s.platform = :ios, '10.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
