## 1.5.7
* Flutter plugins: lower the CocoaPods platform floors to match what the
  native libraries are actually built for — macOS `s.platform` 12.0 -> 10.14
  (`CMAKE_OSX_DEPLOYMENT_TARGET`), iOS 15.0 -> 12.0. Apps no longer need to
  raise their deployment target to depend on `piper_phonemize`.

## 1.5.6
* Add web/WASM support to the `piper_phonemize` Flutter package:
* `PiperPhonemizeInitialize` returns -1 on failure instead of calling
  `exit(1)`.

## 1.5.5
* Fix Android AAR

## 1.5.4
* Fix rust for android

## 1.5.3
* Fix rust

## 1.5.2
* Fix publishing go packages for windows arm64

## 1.5.1
* Fix publishing go packages

## 1.5.0
* Fix for Android.

## 1.4.12
* Fix for Android.

## 1.4.11
* Fix Flutter for iOS.

## 1.4.9
* Support Flutter.

## 1.3.1

* Initial release of piper_phonemize Dart/Flutter package.
* Supports macOS, iOS, Linux, Windows, and Android.
* Provides FFI bindings to the piper-phonemize C API.
* Includes espeak-ng-data for phonemization.
