#!/usr/bin/env bash
#
# Build piper-phonemize JNI shared library for desktop
#
# Usage:
#   ./build-jni.sh

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

dir=build-jni
mkdir -p "$dir"
cd "$dir"

cmake \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -DBUILD_PIPER_PHONEMIZE_JNI=ON \
  ..

make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4) install

echo "---"
echo "Installed libraries:"
ls -lh install/lib/
