#!/usr/bin/env  bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

dir=build-ios
mkdir -p $dir
cd $dir

# First, for simulator
echo "Building for simulator (x86_64)"

cmake \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -S .. \
  -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
  -DPLATFORM=SIMULATOR64 \
  -DENABLE_BITCODE=0 \
  -DENABLE_ARC=1 \
  -DENABLE_VISIBILITY=0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DDEPLOYMENT_TARGET=13.0 \
  -B build/simulator_x86_64

cmake --build build/simulator_x86_64 -j 4

echo "Building for simulator (arm64)"

cmake \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -S .. \
  -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
  -DPLATFORM=SIMULATORARM64 \
  -DENABLE_BITCODE=0 \
  -DENABLE_ARC=1 \
  -DENABLE_VISIBILITY=0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DBUILD_SHARED_LIBS=OFF \
  -DDEPLOYMENT_TARGET=13.0 \
  -B build/simulator_arm64

cmake --build build/simulator_arm64 -j 4

echo "Building for arm64"

cmake \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  -S .. \
  -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
  -DPLATFORM=OS64 \
  -DENABLE_BITCODE=0 \
  -DENABLE_ARC=1 \
  -DENABLE_VISIBILITY=0 \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DDEPLOYMENT_TARGET=13.0 \
  -B build/os64

cmake --build build/os64 -j 4
# Generate headers
cmake --build build/os64 --target install

echo "Generate xcframework"

mkdir -p "build/simulator/lib"
for f in libpiper_phonemize_core.a libespeak-ng.a libucd.a; do
  lipo -create build/simulator_arm64/lib/${f} \
               build/simulator_x86_64/lib/${f} \
       -output build/simulator/lib/${f}
done

# Merge archive first, because the following xcodebuild create xcframework
# cannot accept multi archive with the same architecture.
libtool -static -o build/simulator/libpiper_phonemize.a \
  build/simulator/lib/libpiper_phonemize_core.a \
  build/simulator/lib/libespeak-ng.a \
  build/simulator/lib/libucd.a

libtool -static -o build/os64/libpiper_phonemize.a \
  build/os64/lib/libpiper_phonemize_core.a \
  build/os64/lib/libespeak-ng.a \
  build/os64/lib/libucd.a

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
  cp install/include/piper-phonemize/c-api.h $fw_dir/Headers/piper-phonemize/c-api/

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
  <string>1.4.7</string>
  <key>CFBundleShortVersionString</key>
  <string>1.4.7</string>
  <key>MinimumOSVersion</key>
  <string>13.0</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>iPhoneOS</string>
  </array>
</dict>
</plist>
PEOF
}

create_framework build/os64/libpiper_phonemize.a build/os64
create_framework build/simulator/libpiper_phonemize.a build/simulator

xcodebuild -create-xcframework \
  -framework "build/os64/PiperPhonemizeC.framework" \
  -framework "build/simulator/PiperPhonemizeC.framework" \
  -output piper-phonemize.xcframework

cd piper-phonemize.xcframework
echo "PWD: $PWD"
ls -lh
echo "---"
ls -lh */*

cd ..

PIPER_PHONEMIZE_VERSION=v$(grep "PIPER_PHONEMIZE_VERSION" ../CMakeLists.txt | cut -d " " -f 2 | cut -d ")" -f 1)

rm -f piper-phonemize-${PIPER_PHONEMIZE_VERSION}-ios.xcframework.zip
zip -r -y piper-phonemize-${PIPER_PHONEMIZE_VERSION}-ios.xcframework.zip piper-phonemize.xcframework

echo "Checksum:"
swift package compute-checksum piper-phonemize-${PIPER_PHONEMIZE_VERSION}-ios.xcframework.zip | tee checksum.txt
