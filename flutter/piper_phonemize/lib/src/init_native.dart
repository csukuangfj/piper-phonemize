// Copyright (c) 2026 Xiaomi Corporation
//
// Native library loader for piper-phonemize.
// Following sherpa-onnx init_native.dart pattern.

import 'dart:io';
import 'dart:ffi';

import 'piper_phonemize_bindings.dart';

DynamicLibrary loadDylib(String? path) {
  if (Platform.isMacOS) {
    if (path == null) {
      return DynamicLibrary.process();
    } else {
      // The dylib lives inside the xcframework:
      // macos/piper_phonemize/piper-phonemize.xcframework/macos-arm64_x86_64/libpiper_phonemize_core.dylib
      return DynamicLibrary.open(
          '$path/piper_phonemize/piper-phonemize.xcframework/macos-arm64_x86_64/libpiper_phonemize_core.dylib');
    }
  }

  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }

  if (Platform.isAndroid || Platform.isLinux) {
    if (path == null) {
      return DynamicLibrary.open('libpiper_phonemize_core.so');
    } else {
      return DynamicLibrary.open('$path/libpiper_phonemize_core.so');
    }
  }

  if (Platform.isWindows) {
    if (path == null) {
      return DynamicLibrary.open('piper_phonemize_core.dll');
    } else {
      return DynamicLibrary.open('$path\\piper_phonemize_core.dll');
    }
  }

  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}

void initNativeBindings(String? path) {
  final dylib = loadDylib(path);
  PiperPhonemizeBindings.init(dylib);
}
