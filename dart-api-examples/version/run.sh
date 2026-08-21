#!/usr/bin/env bash

# Copyright (c) 2026 piper-phonemize contributors
#
# Run all Dart CLI version examples.

set -e

cd "$(dirname "$0")"

echo "=== Running main_sync.dart ==="
dart run bin/main_sync.dart

echo ""
echo "=== Running main_async.dart ==="
dart run bin/main_async.dart

echo ""
echo "=== Running main_isolate_sync.dart ==="
dart run bin/main_isolate_sync.dart

echo ""
echo "=== Running main_isolate_async.dart ==="
dart run bin/main_isolate_async.dart
