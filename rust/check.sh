#!/usr/bin/env bash
set -euo pipefail

# Build piper-phonemize native library if not already built
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

if [ ! -d "$PROJECT_DIR/build/install/lib" ]; then
  echo "=== Building piper-phonemize native library ==="
  cd "$PROJECT_DIR"
  mkdir -p build
  cd build
  cmake \
    -DCMAKE_INSTALL_PREFIX=./install \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    ..
  make -j2 install
  cd "$SCRIPT_DIR"
fi

export PIPER_PHONEMIZE_LIB_DIR="$PROJECT_DIR/build/install/lib"

echo "=== Building piper-phonemize ==="
cargo build -p piper-phonemize

echo "=== Checking code with cargo check ==="
cargo check -p piper-phonemize

echo "=== Running clippy for lints ==="
cargo clippy -p piper-phonemize -- -D warnings

echo "=== Running tests ==="
cargo test -p piper-phonemize

echo "All checks passed for piper-phonemize ✅"
