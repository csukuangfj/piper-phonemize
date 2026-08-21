// Copyright (c) 2026 piper-phonemize contributors
//
// FFI bindings for piper-phonemize C API.
// Hand-written (no ffigen) following sherpa-onnx pattern.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Opaque result type
// ---------------------------------------------------------------------------

/// Opaque handle returned by [PiperPhonemizeText].
final class PiperPhonemizeResult extends Opaque {}

// ---------------------------------------------------------------------------
// Function typedefs (Native + Dart)
// ---------------------------------------------------------------------------

// const char *PiperPhonemizeGetVersionStr();
typedef GetVersionStrNative = Pointer<Utf8> Function();
typedef GetVersionStr = Pointer<Utf8> Function();

// int32_t PiperPhonemizeInitialize(const char *data_dir);
typedef InitializeNative = Int32 Function(Pointer<Utf8> dataDir);
typedef Initialize = int Function(Pointer<Utf8> dataDir);

// PiperPhonemizeResult *PiperPhonemizeText(const char *text, const char *voice);
typedef PhonemizeTextNative = Pointer<PiperPhonemizeResult> Function(
    Pointer<Utf8> text, Pointer<Utf8> voice);
typedef PhonemizeText = Pointer<PiperPhonemizeResult> Function(
    Pointer<Utf8> text, Pointer<Utf8> voice);

// int32_t PiperPhonemizeResultGetNumSentences(const PiperPhonemizeResult *result);
typedef ResultGetNumSentencesNative = Int32 Function(
    Pointer<PiperPhonemizeResult> result);
typedef ResultGetNumSentences = int Function(
    Pointer<PiperPhonemizeResult> result);

// int32_t PiperPhonemizeResultGetNumPhonemes(const PiperPhonemizeResult *result, int32_t sentence_id);
typedef ResultGetNumPhonemesNative = Int32 Function(
    Pointer<PiperPhonemizeResult> result, Int32 sentenceId);
typedef ResultGetNumPhonemes = int Function(
    Pointer<PiperPhonemizeResult> result, int sentenceId);

// const uint32_t *PiperPhonemizeResultGetPhonemes(const PiperPhonemizeResult *result, int32_t sentence_id);
typedef ResultGetPhonemesNative = Pointer<Uint32> Function(
    Pointer<PiperPhonemizeResult> result, Int32 sentenceId);
typedef ResultGetPhonemes = Pointer<Uint32> Function(
    Pointer<PiperPhonemizeResult> result, int sentenceId);

// void PiperPhonemizeDestroyResult(PiperPhonemizeResult *result);
typedef DestroyResultNative = Void Function(
    Pointer<PiperPhonemizeResult> result);
typedef DestroyResult = void Function(
    Pointer<PiperPhonemizeResult> result);

// ---------------------------------------------------------------------------
// Bindings class
// ---------------------------------------------------------------------------

class PiperPhonemizeBindings {
  PiperPhonemizeBindings._();

  static GetVersionStr? getVersionStr;
  static Initialize? initialize;
  static PhonemizeText? phonemizeText;
  static ResultGetNumSentences? resultGetNumSentences;
  static ResultGetNumPhonemes? resultGetNumPhonemes;
  static ResultGetPhonemes? resultGetPhonemes;
  static DestroyResult? destroyResult;

  static void init(DynamicLibrary dynamicLibrary) {
    getVersionStr ??= dynamicLibrary
        .lookup<NativeFunction<GetVersionStrNative>>(
            'PiperPhonemizeGetVersionStr')
        .asFunction();

    initialize ??= dynamicLibrary
        .lookup<NativeFunction<InitializeNative>>('PiperPhonemizeInitialize')
        .asFunction();

    phonemizeText ??= dynamicLibrary
        .lookup<NativeFunction<PhonemizeTextNative>>('PiperPhonemizeText')
        .asFunction();

    resultGetNumSentences ??= dynamicLibrary
        .lookup<NativeFunction<ResultGetNumSentencesNative>>(
            'PiperPhonemizeResultGetNumSentences')
        .asFunction();

    resultGetNumPhonemes ??= dynamicLibrary
        .lookup<NativeFunction<ResultGetNumPhonemesNative>>(
            'PiperPhonemizeResultGetNumPhonemes')
        .asFunction();

    resultGetPhonemes ??= dynamicLibrary
        .lookup<NativeFunction<ResultGetPhonemesNative>>(
            'PiperPhonemizeResultGetPhonemes')
        .asFunction();

    destroyResult ??= dynamicLibrary
        .lookup<NativeFunction<DestroyResultNative>>(
            'PiperPhonemizeDestroyResult')
        .asFunction();
  }
}
