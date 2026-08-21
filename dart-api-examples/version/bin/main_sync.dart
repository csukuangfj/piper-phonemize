// Copyright (c) 2026 piper-phonemize contributors
//
// Pure Dart CLI example: sync initialization.

import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void main() {
  // Initialize FFI bindings (resolves path via Isolate.resolvePackageUriSync)
  piper.initBindings();

  // Get and print version
  final version = piper.PiperPhonemize.getVersion();
  print('piper-phonemize version: $version');
}
