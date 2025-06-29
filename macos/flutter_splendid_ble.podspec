#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_splendid_ble.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_splendid_ble'
  s.version          = '0.0.1'
  s.summary          = 'A Bluetooth Low Energy plugin for Flutter.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for interacting with Bluetooth Low Energy (BLE) devices.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Splendid Endeavors' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
