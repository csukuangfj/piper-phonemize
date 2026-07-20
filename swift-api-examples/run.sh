#!/usr/bin/env bash
#
# Build and run the Swift example
#
# Usage:
#   cd swift-api-examples
#   bash run.sh

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Build xcframework if not exists
if [ ! -d "$PROJECT_DIR/build-swift-macos/install" ]; then
  echo "Building piper-phonemize..."
  cd "$PROJECT_DIR"
  bash build-swift-macos.sh
fi

# Download espeak-ng-data if not present
if [ ! -d "$PROJECT_DIR/espeak-ng-data" ]; then
  echo "Downloading espeak-ng-data..."
  cd "$PROJECT_DIR"
  curl -OL https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
  tar xvf espeak-ng-data.tar.bz2
  rm -f espeak-ng-data.tar.bz2
fi

cd "$SCRIPT_DIR"

# Compile
echo "Compiling example..."
swiftc \
  -lc++ \
  -I "$PROJECT_DIR/build-swift-macos/install/include/piper-phonemize" \
  -import-objc-header ./PiperPhonemize-Bridging-Header.h \
  ./example.swift ./PiperPhonemize.swift \
  -L "$PROJECT_DIR/build-swift-macos/install/lib/" \
  -l piper_phonemize \
  -o example

# Run
echo "Running example..."
export DYLD_LIBRARY_PATH="$PROJECT_DIR/build-swift-macos/install/lib:$DYLD_LIBRARY_PATH"
./example "$PROJECT_DIR/espeak-ng-data"
