// Copyright (c) 2026 piper-phonemize contributors
//
// Web WASM loader for piper-phonemize.
// Following the sherpa_onnx_web package's loadWasm() pattern: the emscripten
// bundle ships as package assets, is evaluated in the global scope and
// configured with in-memory `wasmBinary` / `getPreloadedPackage`, so nothing
// is fetched at runtime and no `<script>` tags are needed in the app.
//
// The glue + wrapper are evaluated inside an IIFE whose scope holds `Module`.
// That keeps this package from clobbering (or being clobbered by) a global
// `Module` owned by another emscripten package, e.g. sherpa_onnx_web.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';

import 'init.dart' as web_init;

void _log(String message) {
  if (kDebugMode) {
    print('[piper_phonemize] $message');
  }
}

/// Evaluate [source] in the global scope and return its completion value.
JSAny? _evalJs(String source) {
  final eval = globalContext.getProperty('eval'.toJS) as JSFunction;
  return eval.callAsFunction(null, source.toJS);
}

Future<ByteData> _loadAsset(String assetPath) => rootBundle.load(assetPath);

/// Loads the piper-phonemize WASM module and its JS wrapper.
///
/// Must be called once before using any piper-phonemize API on web.
/// Typically called via `initBindingsAsync()` from this package.
/// Safe to call concurrently — only the first call performs initialization.
class PiperPhonemizeWeb {
  static bool _initialized = false;
  static Completer<void>? _loadingCompleter;

  static Future<void> loadWasm() async {
    if (_initialized) return;

    if (_loadingCompleter != null) {
      return _loadingCompleter!.future;
    }
    _loadingCompleter = Completer<void>();

    try {
      const prefix = 'packages/piper_phonemize/assets/web';

      // 1. JS sources (async I/O).
      _log('Loading JS assets...');
      final glueData = await _loadAsset('$prefix/piper-phonemize-wasm-main.js');
      final wrapperData = await _loadAsset('$prefix/piper-phonemize.js');
      final glueSource = utf8.decode(glueData.buffer
          .asUint8List(glueData.offsetInBytes, glueData.lengthInBytes));
      final wrapperSource = utf8.decode(wrapperData.buffer
          .asUint8List(wrapperData.offsetInBytes, wrapperData.lengthInBytes));

      // 2. WASM binary + the .data package (espeak-ng-data is embedded in it).
      _log('Loading WASM binary...');
      final wasmData =
          await _loadAsset('$prefix/piper-phonemize-wasm-main.wasm');
      final wasmBytes = wasmData.buffer
          .asUint8List(wasmData.offsetInBytes, wasmData.lengthInBytes);

      final packageData =
          await _loadAsset('$prefix/piper-phonemize-wasm-main.data');
      final packageBytes = packageData.buffer
          .asUint8List(packageData.offsetInBytes, packageData.lengthInBytes);

      // getPreloadedPackage must return a real ArrayBuffer (the glue asserts
      // constructor.name === 'ArrayBuffer') whose byte 0 is the first byte of
      // the package — the asset's underlying buffer may be larger and offset,
      // so slice out the exact range with a tiny JS helper.
      final toArrayBuffer = _evalJs(
        '(function (u8) { '
        'return u8.buffer.slice(u8.byteOffset, u8.byteOffset + u8.byteLength); '
        '})',
      )! as JSFunction;

      // 3. Build the emscripten Module config.
      final config = JSObject();
      config['wasmBinary'] = wasmBytes.toJS;

      // The glue calls getPreloadedPackage(name, size) before fetching the
      // .data; returning the bytes here avoids any network request. It must
      // return the data synchronously (not a promise).
      config['getPreloadedPackage'] = ((JSAny name, JSAny size) {
        return toArrayBuffer.callAsFunction(null, packageBytes.toJS);
      }).toJS;

      final ready = Completer<void>();
      config['onRuntimeInitialized'] = (() {
        if (!ready.isCompleted) ready.complete();
      }).toJS;

      // 4. Evaluate glue + wrapper inside an IIFE that owns `Module`, and
      //    return the bundle to Dart.
      _log('Evaluating JS...');
      globalContext['__piperPhonemizeModuleConfig'] = config;
      final jsBundle = _evalJs('''
(function () {
  var Module = globalThis.__piperPhonemizeModuleConfig;
  $glueSource
  $wrapperSource
  return {
    module: Module,
    initialize: piperPhonemizeInitialize,
    phonemize: piperPhonemize,
    getVersion: piperPhonemizeGetVersionStr
  };
})()
''');
      globalContext.delete('__piperPhonemizeModuleConfig'.toJS);

      if (jsBundle == null || !jsBundle.isA<JSObject>()) {
        throw StateError('Failed to evaluate the piper-phonemize WASM bundle');
      }

      // 5. Wait until the emscripten runtime (and the preloaded
      //    espeak-ng-data) is ready.
      await ready.future;

      web_init.setBundle(jsBundle as JSObject);
      _log('WASM module initialized');

      _initialized = true;
      _loadingCompleter!.complete();
    } catch (e) {
      _loadingCompleter!.completeError(e);
      _loadingCompleter = null;
      rethrow;
    }
  }
}
