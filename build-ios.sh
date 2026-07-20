#!/usr/bin/env bash
#
# Build piper-phonemize xcframework for iOS
#
# Usage:
#   ./build-ios.sh

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

dir=build-ios
mkdir -p "$dir"
cd "$dir"

# Build for simulator x86_64
echo "Building for simulator (x86_64)"

cmake \
  -DCMAKE_TOOLCHAIN_FILE=./toolchains/ios.toolchain.cmake \
  -DPLATFORM=SIMULATOR64 \
  -DENABLE_BITCODE=0 \
  -DENABLE_ARC=1 \
  -DENABLE_VISIBILITY=0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -DDEPLOYMENT_TARGET=13.0 \
  -B build/simulator_x86_64 \
  -S ..

cmake --build build/simulator_x86_64 -j 4

# Build for simulator arm64
echo "Building for simulator (arm64)"

cmake \
  -DCMAKE_TOOLCHAIN_FILE=./toolchains/ios.toolchain.cmake \
  -DPLATFORM=SIMULATORARM64 \
  -DENABLE_BITCODE=0 \
  -DENABLE_ARC=1 \
  -DENABLE_VISIBILITY=0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -DDEPLOYMENT_TARGET=13.0 \
  -B build/simulator_arm64 \
  -S ..

cmake --build build/simulator_arm64 -j 4

# Build for device arm64
echo "Building for device (arm64)"

cmake \
  -DCMAKE_TOOLCHAIN_FILE=./toolchains/ios.toolchain.cmake \
  -DPLATFORM=OS64 \
  -DENABLE_BITCODE=0 \
  -DENABLE_ARC=1 \
  -DENABLE_VISIBILITY=0 \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -DDEPLOYMENT_TARGET=13.0 \
  -B build/os64 \
  -S ..

cmake --build build/os64 -j 4
cmake --build build/os64 --target install

echo "Generate xcframework"

# Merge simulator libraries using lipo
mkdir -p "build/simulator/lib"
for f in libpiper_phonemize_core.a libespeak-ng.a libucd.a; do
  lipo -create build/simulator_arm64/lib/${f} \
               build/simulator_x86_64/lib/${f} \
       -output build/simulator/lib/${f}
done

# Merge all .a files into single library for simulator
libtool -static -o build/simulator/libpiper_phonemize.a \
  build/simulator/lib/libpiper_phonemize_core.a \
  build/simulator/lib/libespeak-ng.a \
  build/simulator/lib/libucd.a

# Merge all .a files into single library for device
libtool -static -o build/os64/libpiper_phonemize.a \
  build/os64/lib/libpiper_phonemize_core.a \
  build/os64/lib/libespeak-ng.a \
  build/os64/lib/libucd.a

# Create xcframework
rm -rf piper_phonemize.xcframework

xcodebuild -create-xcframework \
  -library "build/os64/libpiper_phonemize.a" -headers install/include/piper-phonemize \
  -library "build/simulator/libpiper_phonemize.a" -headers install/include/piper-phonemize \
  -output piper_phonemize.xcframework

echo "---"
echo "Xcframework created:"
ls -lh piper_phonemize.xcframework/

# Zip the xcframework
cd "$SCRIPT_DIR/$dir"
rm -f piper-phonemize-ios.xcframework.zip
zip -r -y piper-phonemize-ios.xcframework.zip piper_phonemize.xcframework

echo "---"
echo "Zip created:"
ls -lh piper-phonemize-ios.xcframework.zip

echo "---"
echo "Checksum:"
swift package compute-checksum piper-phonemize-ios.xcframework.zip | tee checksum.txt
