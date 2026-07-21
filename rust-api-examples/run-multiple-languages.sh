#!/usr/bin/env bash
set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Build native library if needed
if [ ! -d "$PROJECT_DIR/build/install/lib" ]; then
  echo "=== Building piper-phonemize native library ==="
  mkdir -p "$PROJECT_DIR/build"
  cd "$PROJECT_DIR/build"
  cmake \
    -DCMAKE_INSTALL_PREFIX=./install \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    ..
  make -j2 install
fi

export PIPER_PHONEMIZE_LIB_DIR="$PROJECT_DIR/build/install/lib"

# Download espeak-ng-data if needed
if [ ! -d "$PROJECT_DIR/espeak-ng-data" ]; then
  echo "=== Downloading espeak-ng-data ==="
  cd "$PROJECT_DIR"
  curl -OL https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
  tar xvf espeak-ng-data.tar.bz2
  rm -f espeak-ng-data.tar.bz2
fi

cd "$SCRIPT_DIR"
cargo run --example multiple_languages -- "$PROJECT_DIR/espeak-ng-data"
