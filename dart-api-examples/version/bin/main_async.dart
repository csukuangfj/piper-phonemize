// Copyright (c) 2026 piper-phonemize contributors
//
// Pure Dart CLI example: async initialization.

import 'package:piper_phonemize/piper_phonemize.dart' as piper;

Future<void> main() async {
  // Initialize FFI bindings (resolves path via Isolate.resolvePackageUri)
  await piper.initBindingsAsync();

  // Get and print version
  final version = piper.PiperPhonemize.getVersion();
  print('piper-phonemize version: $version');
}
