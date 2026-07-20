#!/usr/bin/env bash

set -ex

if [[ ! -f ../../build/install/lib/libpiper_phonemize_core.dylib && ! -f ../../build/install/lib/libpiper_phonemize_core.so ]]; then
  pushd ../../
  mkdir -p build
  cd build

  cmake \
    -DCMAKE_INSTALL_PREFIX=./install \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
    -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
    ..

  make -j2 install
  popd
fi

export PIPER_PHONEMIZE_INSTALL_DIR=$PWD/../../build/install

./node_modules/.bin/cmake-js compile
