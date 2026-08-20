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
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.vendored_frameworks = 'piper_phonemize/piper-phonemize.xcframework'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
