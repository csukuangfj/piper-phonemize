#!/usr/bin/env  bash

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

dir=build-macos-shared-flutter
mkdir -p $dir
cd $dir

cmake \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  ../

make -j4
make install

# Prepare headers directory for xcframework
HEADERS_DIR=include
mkdir -p $HEADERS_DIR/piper-phonemize/c-api
cp install/include/piper-phonemize/c-api.h $HEADERS_DIR/piper-phonemize/c-api/

# Modulemap (required for SPM to resolve the module)
cat > $HEADERS_DIR/module.modulemap << 'EOF'
module PiperPhonemizeC {
  header "piper-phonemize/c-api/c-api.h"
  export *
}
EOF

# Fix dylib install name for rpath loading
install_name_tool -id @rpath/libpiper_phonemize_core.dylib install/lib/libpiper_phonemize_core.dylib

# Ad-hoc sign the dylib so Xcode can embed and re-sign it
codesign --force --sign - install/lib/libpiper_phonemize_core.dylib

rm -rf piper-phonemize.xcframework

xcodebuild -create-xcframework \
  -library install/lib/libpiper_phonemize_core.dylib \
  -headers $HEADERS_DIR \
  -output piper-phonemize.xcframework

PIPER_PHONEMIZE_VERSION=v$(grep "PIPER_PHONEMIZE_VERSION" ../CMakeLists.txt | cut -d " " -f 2 | cut -d ")" -f 1)

rm -f piper-phonemize-${PIPER_PHONEMIZE_VERSION}-macos-shared-flutter.xcframework.zip
zip -r -y piper-phonemize-${PIPER_PHONEMIZE_VERSION}-macos-shared-flutter.xcframework.zip piper-phonemize.xcframework

echo "Checksum:"
swift package compute-checksum piper-phonemize-${PIPER_PHONEMIZE_VERSION}-macos-shared-flutter.xcframework.zip | tee checksum.txt
