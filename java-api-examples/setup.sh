#!/usr/bin/env bash
# Common setup script for piper-phonemize Java API examples
# Source this file at the beginning of each run-xxx.sh script:
#   source ./setup.sh

# Build piper-phonemize JNI lib if not exists
if [[ ! -f ../build-jni/install/lib/libpiper-phonemize-jni.dylib && ! -f ../build-jni/install/lib/libpiper-phonemize-jni.so && ! -f ../build-jni/install/lib/piper-phonemize-jni.dll ]]; then
  mkdir -p ../build-jni
  pushd ../build-jni
  cmake \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    -DBUILD_PIPER_PHONEMIZE_JNI=ON \
    -DCMAKE_INSTALL_PREFIX=./install \
    ..
  make -j4 install
  popd
fi

# Build piper-phonemize JVM jar if not exists
if [ ! -f ../java-api/target/piper-phonemize-jvm-*.jar ]; then
  pushd ../java-api
  mvn package -q
  popd
fi
