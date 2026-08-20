// Copyright (c) 2026 Xiaomi Corporation
//
// Flutter-specific helper for extracting espeak-ng-data from assets.
// This file uses Flutter-only APIs (rootBundle, path_provider).

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Extract espeak-ng-data from Flutter assets to a filesystem directory.
///
/// Returns the absolute path to the extracted directory.
/// Skips extraction if already done (caches by file size).
///
/// This is needed because espeak-ng's `PiperPhonemizeInitialize` requires
/// a filesystem directory path, but Flutter assets are only accessible
/// via [rootBundle].
///
/// Usage (Flutter only):
/// ```dart
/// final dataDir = await extractEspeakNgData();
/// PiperPhonemize.initialize(dataDir);
/// ```
Future<String> extractEspeakNgData() async {
  final appDir = await getApplicationSupportDirectory();
  final targetDir = p.join(appDir.path, 'espeak-ng-data');

  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = manifest.listAssets();
  final espeakAssets =
      allAssets.where((a) => a.startsWith('espeak-ng-data/')).toList();

  for (final asset in espeakAssets) {
    final relativePath = asset.replaceFirst('espeak-ng-data/', '');
    final targetFilePath = p.join(targetDir, relativePath);

    final data = await rootBundle.load(asset);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Check if file already exists with matching size
    final file = File(targetFilePath);
    if (await file.exists() && await file.length() == bytes.length) {
      continue;
    }

    // Create parent directories and write file
    await Directory(p.dirname(targetFilePath)).create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  return targetDir;
}
