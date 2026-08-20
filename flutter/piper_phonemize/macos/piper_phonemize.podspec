Pod::Spec.new do |s|
  s.name             = 'piper_phonemize'
  s.version          = '1.4.8'
  s.summary          = 'Flutter FFI plugin for piper-phonemize.'
  s.description      = <<-DESC
Dart and Flutter bindings for piper-phonemize, a fast phonemization library
backed by espeak-ng.
                       DESC
  s.homepage         = 'https://github.com/csukuangfj/piper-phonemize'
  s.license          = { :type => 'GPL-3.0' }
  s.author           = { 'Fangjun Kuang' => 'csukuangfj@gmail.com' }

  s.source           = { :path => '.' }
  s.dependency 'FlutterMacOS'

  s.vendored_libraries = 'piper_phonemize/piper-phonemize.xcframework/macos-arm64_x86_64/libpiper_phonemize_core.dylib'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
