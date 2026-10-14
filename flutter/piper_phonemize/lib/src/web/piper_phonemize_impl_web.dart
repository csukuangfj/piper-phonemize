// Copyright (c) 2026 piper-phonemize contributors
//
// Web implementation of the PiperPhonemize API (dart:js_interop).
// Mirrors src/piper_phonemize_impl.dart (the dart:ffi version) so the same
// application code runs on native and web.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'init.dart';

JSFunction _fn(String name) {
  final f = getBundle()[name] as JSFunction?;
  if (f == null) {
    throw StateError('piper-phonemize WASM bundle has no `$name` function');
  }
  return f;
}

class PiperPhonemize {
  PiperPhonemize._();

  /// Get the piper-phonemize version string.
  static String getVersion() {
    final result = _fn('getVersion').callAsFunction(null);
    return (result! as JSString).toDart;
  }

  /// Initialize espeak-ng.
  ///
  /// Must be called before [phonemize].
  ///
  /// On web, the espeak-ng-data is embedded in the WASM bundle's `.data`
  /// package (preloaded at `/usr/share/espeak-ng-data`), so [dataDir] is
  /// **ignored**. It is kept in the signature for API parity with native,
  /// where it points at a real espeak-ng-data directory.
  ///
  /// Returns the sample rate (22050) on first call, 0 on subsequent calls,
  /// or -1 on failure.
  static int initialize(String dataDir) {
    final result = _fn('initialize').callAsFunction(null);
    return (result! as JSNumber).toDartInt;
  }

  /// Phonemize [text] using the given [voice] (default: 'en-us').
  ///
  /// Returns a list of sentences, where each sentence is a list of
  /// Unicode code points (phonemes). Returns an empty list on failure,
  /// matching the native implementation.
  static List<List<int>> phonemize(String text, {String voice = 'en-us'}) {
    final result = _fn('phonemize')
        .callAsFunction(null, text.toJS, (voice).toJS);
    if (result == null) return [];

    final jsSentences = (result as JSArray).toDart;
    final sentences = <List<int>>[];
    for (final jsSentence in jsSentences) {
      if (jsSentence == null) {
        sentences.add(<int>[]);
        continue;
      }
      final jsPhonemes = (jsSentence as JSArray).toDart;
      sentences.add([
        for (final p in jsPhonemes) (p! as JSNumber).toDartInt,
      ]);
    }
    return sentences;
  }
}
