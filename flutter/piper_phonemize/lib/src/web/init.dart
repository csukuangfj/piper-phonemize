// Copyright (c) 2026 piper-phonemize contributors
//
// Web platform initialization using dart:js_interop.
// Following the sherpa-onnx flutter package's src/web/init.dart pattern.
//
// The WASM module is loaded by PiperPhonemizeWeb.loadWasm() (see
// src/web/init_stub.dart) which evaluates the emscripten glue in its own
// scope and hands us the resulting JS bundle. We deliberately keep the
// bundle in a private Dart-side reference instead of a global `Module`, so
// this package can coexist with other emscripten packages (e.g.
// sherpa_onnx_web) in the same app.

import 'dart:js_interop';

JSObject? _bundle;

/// Store the loaded JS bundle. Called by [PiperPhonemizeWeb.loadWasm].
void setBundle(JSObject bundle) {
  _bundle = bundle;
}

/// Get the loaded JS bundle.
///
/// The bundle is a JS object with these members:
/// - `module`: the emscripten `Module` (runtime + `_PiperPhonemize*` exports)
/// - `initialize`, `phonemize`, `getVersion`: the functions from
///   `piper-phonemize.js`, bound to that `Module`.
///
/// Must be called after [PiperPhonemizeWeb.loadWasm] has completed.
JSObject getBundle() {
  if (_bundle != null) return _bundle!;
  throw StateError(
    'piper-phonemize WASM module not loaded. '
    'Call PiperPhonemizeWeb.loadWasm() first (or initBindingsAsync()).',
  );
}

// No-op for web — loading is handled by PiperPhonemizeWeb.loadWasm().
void initNativeBindings(String? path) {
  // Not used on web.
}
