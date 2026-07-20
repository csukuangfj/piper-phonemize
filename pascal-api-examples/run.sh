#!/usr/bin/env bash

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Build piper-phonemize if not already built
if [ ! -d "$PROJECT_DIR/build/install" ]; then
  echo "Building piper-phonemize..."
  cd "$PROJECT_DIR"
  mkdir -p build
  cd build
  cmake \
    -DCMAKE_INSTALL_PREFIX=./install \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    ..
  make -j2 install
  cd "$SCRIPT_DIR"
fi

# Download espeak-ng-data if not present
if [ ! -d "$PROJECT_DIR/espeak-ng-data" ]; then
  echo "Downloading espeak-ng-data..."
  cd "$PROJECT_DIR"
  curl -OL https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
  tar xvf espeak-ng-data.tar.bz2
  rm -f espeak-ng-data.tar.bz2
  cd "$SCRIPT_DIR"
fi

# Compile the example
echo "Compiling example..."
fpc \
  -dPIPER_PHONEMIZE_USE_SHARED_LIBS \
  -Fu"$PROJECT_DIR/src/pascal-api" \
  -Fl"$PROJECT_DIR/build/install/lib" \
  ./example.pas

# Run the example
echo "Running example..."
if [ "$(uname)" = "Darwin" ]; then
  export DYLD_LIBRARY_PATH="$PROJECT_DIR/build/install/lib:$DYLD_LIBRARY_PATH"
else
  export LD_LIBRARY_PATH="$PROJECT_DIR/build/install/lib:$LD_LIBRARY_PATH"
fi

./example "$PROJECT_DIR/espeak-ng-data"
