#!/usr/bin/env bash
#
# Build piper-phonemize for WASM (Node.js target)
#
# Prerequisites:
#   - Emscripten SDK (emsdk) installed and activated
#   - Set EMSCRIPTEN env var or have emcc on PATH
#
# Usage:
#   source /path/to/emsdk/emsdk_env.sh
#   ./build-wasm-simd-nodejs.sh

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Find Emscripten
if [ -z "$EMSCRIPTEN" ]; then
  if command -v emcc &> /dev/null; then
    EMSCRIPTEN=$(dirname $(realpath $(which emcc)))
    emcc --version
  else
    echo "Error: EMSCRIPTEN not set and emcc not found on PATH"
    echo "Please install and activate emsdk first:"
    echo "  git clone https://github.com/emscripten-core/emsdk.git"
    echo "  cd emsdk && ./emsdk install 4.0.23 && ./emsdk activate 4.0.23"
    echo "  source emsdk_env.sh"
    exit 1
  fi
fi

if [ ! -f "$EMSCRIPTEN/cmake/Modules/Platform/Emscripten.cmake" ]; then
  echo "Error: Emscripten.cmake not found at $EMSCRIPTEN"
  exit 1
fi

echo "Using Emscripten at: $EMSCRIPTEN"

BUILD_DIR="${SCRIPT_DIR}/build-wasm-simd-nodejs"
INSTALL_DIR="${BUILD_DIR}/install"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake \
  -DCMAKE_TOOLCHAIN_FILE="$EMSCRIPTEN/cmake/Modules/Platform/Emscripten.cmake" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_EXE=OFF \
  -DPIPER_PHONEMIZE_ENABLE_WASM=ON \
  -DPIPER_PHONEMIZE_ENABLE_WASM_NODEJS=ON \
  "$SCRIPT_DIR"

make -j"$(nproc)"
make install

echo ""
echo "Build complete!"
echo "Output directory: $INSTALL_DIR/bin/wasm/nodejs/"
echo ""
echo "Files:"
ls -lh "$INSTALL_DIR/bin/wasm/nodejs/"
