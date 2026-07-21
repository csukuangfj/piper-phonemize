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

cd "$SCRIPT_DIR"
cargo run --example multiple_languages
