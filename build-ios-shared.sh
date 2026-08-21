#!/usr/bin/env  bash
#
# Note: This script is to build piper-phonemize for flutter/dart, which requires
# us to use shared libraries for piper-phonemize.
#
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

dir=build-ios-shared
mkdir -p $dir
cd $dir

# First, for simulator
echo "Building for simulator (x86_64)"

if [[ ! -f build/simulator_x86_64/install/lib/libpiper_phonemize_core.dylib ]]; then
  cmake \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    -S .. \
    -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
    -DPLATFORM=SIMULATOR64 \
    -DENABLE_BITCODE=0 \
    -DENABLE_ARC=1 \
    -DENABLE_VISIBILITY=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=./build/simulator_x86_64/install \
    -DBUILD_SHARED_LIBS=ON \
    -DDEPLOYMENT_TARGET=13.0 \
    -B build/simulator_x86_64

  cmake --build build/simulator_x86_64 -j 4 --target install
else
  echo "Skip building for simulator (x86_64)"
fi

echo "Building for simulator (arm64)"

if [[ ! -f build/simulator_arm64/install/lib/libpiper_phonemize_core.dylib ]]; then
  cmake \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    -S .. \
    -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
    -DPLATFORM=SIMULATORARM64 \
    -DENABLE_BITCODE=0 \
    -DENABLE_ARC=1 \
    -DENABLE_VISIBILITY=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=./build/simulator_arm64/install \
    -DBUILD_SHARED_LIBS=ON \
    -DDEPLOYMENT_TARGET=13.0 \
    -B build/simulator_arm64

  cmake --build build/simulator_arm64 -j 4 --target install
else
  echo "Skip building for simulator (arm64)"
fi

echo "Building for arm64"

if [[ ! -f build/os64/install/lib/libpiper_phonemize_core.dylib ]]; then
  cmake \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    -S .. \
    -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
    -DPLATFORM=OS64 \
    -DENABLE_BITCODE=0 \
    -DENABLE_ARC=1 \
    -DENABLE_VISIBILITY=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=./build/os64/install \
    -DBUILD_SHARED_LIBS=ON \
    -DDEPLOYMENT_TARGET=13.0 \
    -B build/os64

  cmake --build build/os64 -j 4 --target install
else
  echo "Skip building for arm64"
fi

echo "Collect dynamic libraries"
mkdir -p ios-arm64 ios-arm64-simulator ios-x86_64-simulator

cp -v ./build/os64/install/lib/libpiper_phonemize_core.dylib ios-arm64/
cp -v ./build/simulator_arm64/install/lib/libpiper_phonemize_core.dylib ios-arm64-simulator/
cp -v ./build/simulator_x86_64/install/lib/libpiper_phonemize_core.dylib ios-x86_64-simulator/

# Merge simulator dylibs
rm -rf ios-arm64_x86_64-simulator
mkdir ios-arm64_x86_64-simulator

lipo \
  -create \
    ios-arm64-simulator/libpiper_phonemize_core.dylib \
    ios-x86_64-simulator/libpiper_phonemize_core.dylib \
  -output \
    ios-arm64_x86_64-simulator/libpiper_phonemize_core.dylib

rm -rf piper-phonemize.xcframework

# Create framework bundles so SPM can resolve the module
create_framework() {
  local lib_path=$1
  local output_dir=$2

  local fw_dir=$output_dir/PiperPhonemizeC.framework
  rm -rf $fw_dir

  mkdir -p $fw_dir/Headers/piper-phonemize/c-api
  mkdir -p $fw_dir/Modules

  cp $lib_path $fw_dir/PiperPhonemizeC
  cp build/os64/install/include/piper-phonemize/c-api.h $fw_dir/Headers/piper-phonemize/c-api/

  cat > $fw_dir/Modules/module.modulemap << 'MEOF'
framework module PiperPhonemizeC {
  header "piper-phonemize/c-api/c-api.h"
  export *
}
MEOF

  cat > $fw_dir/Info.plist << 'PEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.xiaomi.piper-phonemize</string>
  <key>CFBundleName</key>
  <string>PiperPhonemizeC</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleExecutable</key>
  <string>PiperPhonemizeC</string>
  <key>CFBundleVersion</key>
  <string>1.4.9</string>
  <key>CFBundleShortVersionString</key>
  <string>1.4.9</string>
  <key>MinimumOSVersion</key>
  <string>13.0</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>iPhoneOS</string>
  </array>
</dict>
</plist>
PEOF

  # Fix dylib install name
  install_name_tool -id @rpath/PiperPhonemizeC.framework/PiperPhonemizeC $fw_dir/PiperPhonemizeC

  # Ad-hoc sign the framework binary so Xcode can embed and re-sign it
  codesign --force --sign - $fw_dir/PiperPhonemizeC
}

create_framework ios-arm64/libpiper_phonemize_core.dylib ios-arm64
create_framework ios-arm64_x86_64-simulator/libpiper_phonemize_core.dylib ios-arm64_x86_64-simulator

xcodebuild -create-xcframework \
  -framework "ios-arm64/PiperPhonemizeC.framework" \
  -framework "ios-arm64_x86_64-simulator/PiperPhonemizeC.framework" \
  -output piper-phonemize.xcframework

cd piper-phonemize.xcframework
echo "PWD: $PWD"
ls -lh
echo "---"
ls -lh */*

cd ..

PIPER_PHONEMIZE_VERSION=v$(grep "PIPER_PHONEMIZE_VERSION" ../CMakeLists.txt | cut -d " " -f 2 | cut -d ")" -f 1)

rm -f piper-phonemize-${PIPER_PHONEMIZE_VERSION}-ios-shared.xcframework.zip
zip -r -y piper-phonemize-${PIPER_PHONEMIZE_VERSION}-ios-shared.xcframework.zip piper-phonemize.xcframework

echo "Checksum:"
swift package compute-checksum piper-phonemize-${PIPER_PHONEMIZE_VERSION}-ios-shared.xcframework.zip | tee checksum.txt
