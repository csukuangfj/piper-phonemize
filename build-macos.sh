#!/usr/bin/env  bash

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

dir=build-macos
mkdir -p $dir
cd $dir

cmake \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  ../

make -j4
make install

# Merge all .a files into single library
cd install/lib
libtool -static -o libpiper_phonemize.a \
  libpiper_phonemize_core.a \
  libespeak-ng.a \
  libucd.a

cd "$SCRIPT_DIR/$dir"

# Create a framework bundle so SPM can resolve the module
FRAMEWORK_DIR=PiperPhonemizeC.framework
rm -rf $FRAMEWORK_DIR

mkdir -p $FRAMEWORK_DIR/Headers/piper-phonemize/c-api
mkdir -p $FRAMEWORK_DIR/Modules

# Binary
cp install/lib/libpiper_phonemize.a $FRAMEWORK_DIR/PiperPhonemizeC

# Headers (preserve nested path for #include "piper-phonemize/c-api/c-api.h")
cp install/include/piper-phonemize/c-api.h $FRAMEWORK_DIR/Headers/piper-phonemize/c-api/

# Modulemap
cat > $FRAMEWORK_DIR/Modules/module.modulemap << 'EOF'
framework module PiperPhonemizeC {
  header "piper-phonemize/c-api/c-api.h"
  export *
}
EOF

# Info.plist
cat > $FRAMEWORK_DIR/Info.plist << 'EOF'
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
</dict>
</plist>
EOF

rm -rf piper-phonemize.xcframework

xcodebuild -create-xcframework \
  -framework $FRAMEWORK_DIR \
  -output piper-phonemize.xcframework

PIPER_PHONEMIZE_VERSION=v$(grep "PIPER_PHONEMIZE_VERSION" ../CMakeLists.txt | cut -d " " -f 2 | cut -d ")" -f 1)

rm -f piper-phonemize-${PIPER_PHONEMIZE_VERSION}-macos.xcframework.zip
zip -r -y piper-phonemize-${PIPER_PHONEMIZE_VERSION}-macos.xcframework.zip piper-phonemize.xcframework

echo "Checksum:"
swift package compute-checksum piper-phonemize-${PIPER_PHONEMIZE_VERSION}-macos.xcframework.zip | tee checksum.txt
