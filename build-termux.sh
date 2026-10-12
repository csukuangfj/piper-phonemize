#!/usr/bin/env bash
# Build piper-phonemize inside a termux/termux-docker container.
#
# Unlike build-android-*.sh, which cross-compile with the Android NDK toolchain
# (and therefore the NDK libc++, inline namespace std::__ndk1), this uses
# Termux's own clang/libc++ (inline namespace std::__1).
#
# The NDK-built libraries cannot be linked in Termux: Termux links its own
# libc++ ("std::__1"), so every "std::__ndk1::..." symbol referenced by the
# NDK archives is undefined there. The libraries produced here link cleanly in
# Termux (and anywhere else that uses a non-NDK libc++).
#
# Run it like:
#   docker run --rm -v $PWD:/work -w /work termux/termux-docker:aarch64 \
#     bash -c 'apt update && apt install -y cmake make git clang libc++ && \
#              BUILD_SHARED_LIBS=OFF ./build-termux.sh'
set -ex

if [ -z "$BUILD_SHARED_LIBS" ]; then
  BUILD_SHARED_LIBS=OFF
fi

if [ "$BUILD_SHARED_LIBS" = ON ]; then
  dir=$PWD/build-termux-shared
else
  dir=$PWD/build-termux
fi

echo "BUILD_SHARED_LIBS: $BUILD_SHARED_LIBS"

mkdir -p "$dir"
cd "$dir"

cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  ..

cmake --build . -j"$(nproc)"
cmake --install .

echo "Done! Libraries are in $dir/install/lib/"
ls -lh install/lib/
