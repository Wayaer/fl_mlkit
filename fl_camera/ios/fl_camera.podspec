Pod::Spec.new do |s|
  s.name             = 'fl_camera'
  s.version          = '5.0.0'
  s.summary          = 'A camera plugin for Flutter, supports Android (CameraX) and iOS (AVFoundation).'
  s.description      = <<-DESC
A camera plugin for Flutter with preview, flash, zoom and camera switching.
Supports Android (CameraX) and iOS (AVFoundation).
                       DESC
  s.homepage         = 'https://github.com/Wayaer/fl_mlkit/tree/main/fl_camera'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Wayaer' => 'https://github.com/Wayaer' }
  s.source           = { :path => '.' }
  s.source_files     = 'fl_camera/Sources/fl_camera/**/*.swift'
  s.resource_bundles = { 'fl_camera_privacy' => ['fl_camera/Sources/fl_camera/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.dependency 'fl_channel'
  s.ios.deployment_target = '15.5'
  s.pod_target_xcconfig  = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
