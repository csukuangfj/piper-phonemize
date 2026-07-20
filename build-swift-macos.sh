#!/usr/bin/env bash
#
# Build piper-phonemize xcframework for macOS (Swift)
#
# Usage:
#   ./build-swift-macos.sh

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

BUILD_DIR=build-swift-macos

# Build for macOS (universal arm64 + x86_64)
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  ..

make -j$(sysctl -n hw.ncpu) install

echo "---"
echo "Installed libraries:"
ls -lh install/lib/

echo "---"
echo "Installed headers:"
ls -lh install/include/piper-phonemize/

# Merge all .a files into single library
cd install/lib
libtool -static -o libpiper_phonemize.a \
  libpiper_phonemize_core.a \
  libespeak-ng.a \
  libucd.a

echo "---"
echo "Merged library:"
ls -lh libpiper_phonemize.a

# Create xcframework
cd "$SCRIPT_DIR/$BUILD_DIR"

rm -rf piper_phonemize.xcframework
xcodebuild -create-xcframework \
  -library install/lib/libpiper_phonemize.a \
  -headers install/include/piper-phonemize \
  -output piper_phonemize.xcframework

echo "---"
echo "Xcframework created:"
ls -lh piper_phonemize.xcframework/

# Zip the xcframework
cd "$SCRIPT_DIR/$BUILD_DIR"
rm -f piper-phonemize-macos.xcframework.zip
zip -r -y piper-phonemize-macos.xcframework.zip piper_phonemize.xcframework

echo "---"
echo "Zip created:"
ls -lh piper-phonemize-macos.xcframework.zip

echo "---"
echo "Checksum:"
swift package compute-checksum piper-phonemize-macos.xcframework.zip | tee checksum.txt
