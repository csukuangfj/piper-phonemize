#!/usr/bin/env bash
set -ex

if [ -z $BUILD_SHARED_LIBS ]; then
  BUILD_SHARED_LIBS=ON
fi

if [ $BUILD_SHARED_LIBS == ON ]; then
  dir=$PWD/build-android-armv7-eabi
else
  dir=$PWD/build-android-armv7-eabi-static
fi

if [ -z $ANDROID_NDK ]; then
  ANDROID_NDK=/star-fj/fangjun/software/android-sdk/ndk/22.1.7171670

  if [ $BUILD_SHARED_LIBS == OFF ]; then
    ANDROID_NDK=/star-fj/fangjun/software/android-sdk/ndk/27.0.11718014
  fi

  if [ ! -d $ANDROID_NDK ]; then
    # For macOS with Android Studio
    ANDROID_NDK=/Users/fangjun/software/my-android/ndk/22.1.7171670

    if [ $BUILD_SHARED_LIBS == OFF ]; then
      ANDROID_NDK=/Users/fangjun/software/my-android/ndk/27.0.11718014
    fi
  fi
fi

if [ ! -d $ANDROID_NDK ]; then
  echo "Please set the environment variable ANDROID_NDK before you run this script"
  exit 1
fi

echo "ANDROID_NDK: $ANDROID_NDK"
echo "BUILD_SHARED_LIBS: $BUILD_SHARED_LIBS"

mkdir -p $dir
cd $dir

cmake \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="armeabi-v7a" \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=./install \
  -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
  -DBUILD_PIPER_PHONEMIZE_PYTHON=OFF \
  -DBUILD_PIPER_PHONEMIZE_CORE_TESTS=OFF \
  ..

make -j4
make install/strip

echo "Done! Libraries are in $dir/install/lib/"
ls -lh install/lib/
