#!/usr/bin/env bash
#
# Build piper-phonemize for WASM (Browser target)
#
# Prerequisites:
#   - Emscripten SDK (emsdk) installed and activated
#   - Set EMSCRIPTEN env var or have emcc on PATH
#   - espeak-ng-data in wasm/browser/assets/ (see assets/README.md)
#
# Usage:
#   source /path/to/emsdk/emsdk_env.sh
#   ./build-wasm-simd-browser.sh

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

# Download espeak-ng-data if not present
ASSETS_DIR="${SCRIPT_DIR}/wasm/browser/assets"
if [ ! -d "${ASSETS_DIR}/espeak-ng-data" ]; then
  echo "Downloading espeak-ng-data..."
  cd "${ASSETS_DIR}"
  curl -OL https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
  tar xvf espeak-ng-data.tar.bz2
  rm -f espeak-ng-data.tar.bz2
  cd "${SCRIPT_DIR}"
fi

# Set environment variable for CMake check
export PIPER_PHONEMIZE_IS_USING_BUILD_WASM_SH=1

BUILD_DIR="${SCRIPT_DIR}/build-wasm-simd-browser"
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
  -DPIPER_PHONEMIZE_ENABLE_WASM_BROWSER=ON \
  "$SCRIPT_DIR"

make -j"$(nproc)"
make install

echo ""
echo "Build complete!"
echo "Output directory: $INSTALL_DIR/bin/wasm/browser/"
echo ""
echo "Files:"
ls -lh "$INSTALL_DIR/bin/wasm/browser/"
echo ""
echo "To test locally:"
echo "  cd $INSTALL_DIR/bin/wasm/browser"
echo "  python3 -m http.server 8080"
echo "  # Open http://localhost:8080 in your browser"
