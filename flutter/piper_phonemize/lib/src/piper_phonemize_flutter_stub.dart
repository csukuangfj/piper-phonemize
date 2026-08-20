// Copyright (c) 2026 Xiaomi Corporation
//
// Stub for extractEspeakNgData in pure Dart CLI (no Flutter).
// Throws if called — this function only works in Flutter apps.

/// Extract espeak-ng-data from Flutter assets to a filesystem directory.
///
/// This function is only available in Flutter apps. In pure Dart CLI,
/// pass the espeak-ng-data directory path directly to
/// `PiperPhonemize.initialize()`.
Future<String> extractEspeakNgData() {
  throw UnsupportedError(
    'extractEspeakNgData() is only available in Flutter apps. '
    'In Dart CLI, pass the espeak-ng-data path directly to '
    'PiperPhonemize.initialize().',
  );
}
