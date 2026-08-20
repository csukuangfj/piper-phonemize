// Copyright (c) 2026 Xiaomi Corporation
//
// Main export for piper_phonemize package.
// Initialization logic follows sherpa-onnx pattern exactly.

import 'dart:io' show Platform;
import 'dart:isolate' show Isolate;

// Conditional import: native uses dart:ffi, web uses dart:js_interop.
import 'src/init_native.dart'
    if (dart.library.js_interop) 'src/web/init.dart' as init;

// Conditional import for web WASM loader.
import 'package:piper_phonemize/src/init_stub.dart'
    if (dart.library.js_interop) 'package:piper_phonemize/src/web/init_stub.dart'
    as web;

export 'src/piper_phonemize_bindings.dart';
export 'src/piper_phonemize_impl.dart';
export 'src/piper_phonemize_flutter_stub.dart'
    if (dart.library.ui) 'src/piper_phonemize_flutter.dart';

String? _path;

// On native platforms (dart:io available), this is always false.
// On web (dart:js_interop available), the web init.dart is loaded instead.
const bool _kIsWeb = bool.fromEnvironment('dart.library.io') == false;

// For Dart CLI: resolve the path to the native library within this package.
// Resolves package:piper_phonemize/any.dart → /pub-cache/piper_phonemize-x.y.z/lib/any.dart
// Then navigates: lib/ → package root → platform subdir (e.g., linux/x64/)
String? _resolvePath(Uri uri) {
  final filePath = uri.toFilePath();
  final sep = Platform.pathSeparator;
  final libDir = filePath.substring(0, filePath.lastIndexOf(sep));
  final parentDir = libDir.endsWith('${sep}lib')
      ? libDir.substring(0, libDir.length - 4)
      : libDir;

  if (Platform.isLinux) {
    final arch = Platform.version.contains('arm64') ||
            Platform.version.contains('aarch64')
        ? 'aarch64'
        : 'x64';
    return '$parentDir${sep}linux${sep}$arch';
  }

  if (Platform.isWindows) {
    final arch = Platform.version.contains('arm64') ? 'arm64' : 'x64';
    return '$parentDir${sep}windows${sep}$arch';
  }

  return '$parentDir${sep}macos';
}

/// Resolve the path to the piper-phonemize native library (async).
///
/// Uses [Isolate.resolvePackageUri] to locate the package directory
/// in the pub cache.
///
/// Returns `null` on unsupported platforms or if resolution fails
/// (e.g., in Flutter where Isolate.resolvePackageUri is not supported).
Future<String?> resolvePiperPhonemizePath() async {
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    final uri = await Isolate.resolvePackageUri(
        Uri.parse('package:piper_phonemize/any_path_is_ok_here.dart'));
    if (uri == null) return null;
    return _resolvePath(uri);
  }
  return null; // iOS, Android: not needed (DynamicLibrary.process() or linker)
}

/// Resolve the path to the piper-phonemize native library (sync).
///
/// Uses [Isolate.resolvePackageUriSync] to locate the package directory
/// in the pub cache. Returns `null` if not supported (e.g., Flutter)
/// or if the package cannot be found.
String? resolvePiperPhonemizePathSync() {
  try {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final uri = Isolate.resolvePackageUriSync(
          Uri.parse('package:piper_phonemize/any_path_is_ok_here.dart'));
      if (uri == null) return null;
      return _resolvePath(uri);
    }
    return null;
  } catch (_) {
    // Not supported in Flutter.
    return null;
  }
}

/// Initialize the native piper-phonemize bindings synchronously.
///
/// Works on Flutter and Dart CLI without a path argument — the native
/// library location is auto-resolved. On Flutter, uses
/// `DynamicLibrary.process()`; on Dart CLI, locates the library in the
/// pub cache via [resolvePiperPhonemizePathSync].
///
/// Does **not** support web — use [initBindingsAsync] instead.
///
/// **Isolates:** Each isolate has its own FFI binding state. You must call
/// [initBindings] or [initBindingsAsync] in every isolate that uses
/// piper-phonemize APIs.
void initBindings([String? p]) {
  if (_kIsWeb) {
    throw UnsupportedError(
      'initBindings() is not supported on web. '
      'Use initBindingsAsync() instead.',
    );
  }
  p ??= resolvePiperPhonemizePathSync();
  _path ??= p;
  init.initNativeBindings(_path);
}

/// Initialize the piper-phonemize bindings asynchronously.
///
/// Works on all platforms including web. On native platforms, the native
/// library path is auto-resolved (no argument needed). On web, loads the
/// WASM module from bundled assets.
///
/// **Isolates:** Each isolate has its own FFI binding state. You must call
/// [initBindings] or [initBindingsAsync] in every isolate that uses
/// piper-phonemize APIs.
Future<void> initBindingsAsync([String? p]) async {
  if (p == null && !_kIsWeb) {
    try {
      p = await resolvePiperPhonemizePath();
    } catch (_) {
      // Isolate.resolvePackageUri is not supported in Flutter.
      // Fall back to DynamicLibrary.process() via initNativeBindings(null).
    }
  }
  _path ??= p;
  if (_kIsWeb) {
    await web.PiperPhonemizeWeb.loadWasm();
    return;
  }
  init.initNativeBindings(_path);
}
