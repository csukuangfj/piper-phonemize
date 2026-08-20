// Copyright (c) 2026 Xiaomi Corporation
//
// High-level Dart API for piper-phonemize.
// Core API works on both Flutter and Dart CLI.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'piper_phonemize_bindings.dart';

class PiperPhonemize {
  PiperPhonemize._();

  /// Get the piper-phonemize version string.
  static String getVersion() {
    final ptr = PiperPhonemizeBindings.getVersionStr!();
    return ptr.toDartString();
  }

  /// Initialize espeak-ng with the given data directory.
  ///
  /// Must be called before [phonemize].
  /// Returns the sample rate (22050) on first call, 0 on subsequent calls,
  /// or -1 on failure.
  static int initialize(String dataDir) {
    final dataDirPtr = dataDir.toNativeUtf8();
    try {
      return PiperPhonemizeBindings.initialize!(dataDirPtr);
    } finally {
      calloc.free(dataDirPtr);
    }
  }

  /// Phonemize [text] using the given [voice] (default: 'en-us').
  ///
  /// Returns a list of sentences, where each sentence is a list of
  /// Unicode code points (phonemes).
  static List<List<int>> phonemize(String text, {String voice = 'en-us'}) {
    final textPtr = text.toNativeUtf8();
    final voicePtr = voice.toNativeUtf8();
    try {
      final result = PiperPhonemizeBindings.phonemizeText!(textPtr, voicePtr);
      if (result == nullptr) {
        return [];
      }

      try {
        final numSentences =
            PiperPhonemizeBindings.resultGetNumSentences!(result);
        final sentences = <List<int>>[];

        for (var i = 0; i < numSentences; i++) {
          final numPhonemes =
              PiperPhonemizeBindings.resultGetNumPhonemes!(result, i);
          if (numPhonemes <= 0) {
            sentences.add([]);
            continue;
          }

          final phonemesPtr =
              PiperPhonemizeBindings.resultGetPhonemes!(result, i);
          final phonemes = <int>[];
          for (var j = 0; j < numPhonemes; j++) {
            phonemes.add(phonemesPtr[j]);
          }
          sentences.add(phonemes);
        }

        return sentences;
      } finally {
        PiperPhonemizeBindings.destroyResult!(result);
      }
    } finally {
      calloc.free(textPtr);
      calloc.free(voicePtr);
    }
  }
}
