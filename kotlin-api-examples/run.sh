#!/usr/bin/env bash
#
# Build and run the Kotlin example
#
# Usage:
#   cd kotlin-api-examples
#   bash run.sh

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Build JNI lib if not exists
if [[ ! -f "$PROJECT_DIR/build-jni/install/lib/libpiper-phonemize-jni.dylib" && ! -f "$PROJECT_DIR/build-jni/install/lib/libpiper-phonemize-jni.so" ]]; then
  echo "Building piper-phonemize JNI..."
  cd "$PROJECT_DIR"
  mkdir -p build-jni && cd build-jni
  cmake \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    -DBUILD_PIPER_PHONEMIZE_JNI=ON \
    -DCMAKE_INSTALL_PREFIX=./install \
    ..
  make -j4 install
fi

cd "$SCRIPT_DIR"

# Compile
echo "Compiling Kotlin example..."
kotlinc-jvm -include-runtime -d PhonemizeText.jar \
  PhonemizeText.kt \
  "$PROJECT_DIR/kotlin-api/PiperPhonemize.kt"

ls -lh PhonemizeText.jar

# Run
echo "Running example..."
java -Djava.library.path="$PROJECT_DIR/build-jni/install/lib" -jar PhonemizeText.jar
