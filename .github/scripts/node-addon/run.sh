#!/usr/bin/env bash

piper_phonemize_dir=$PWD
echo "piper_phonemize_dir: $piper_phonemize_dir"

src_dir=$piper_phonemize_dir/.github/scripts/node-addon

platform=$(node -p "require('os').platform()")

arch=$(node -p "require('os').arch()")

echo "platform: $platform"
echo "arch: $arch"

# ia32 for win x86

platform2=$platform


if [[ $platform == win32 ]]; then
  platform2=win
fi


PIPER_PHONEMIZE_VERSION=$(grep "set(PIPER_PHONEMIZE_VERSION" ./CMakeLists.txt | sed 's/.*set(PIPER_PHONEMIZE_VERSION \(.*\))/\1/' | tr -d ' ")')
echo "PIPER_PHONEMIZE_VERSION: $PIPER_PHONEMIZE_VERSION"

sed -i.bak s/PIPER_PHONEMIZE_VERSION/$PIPER_PHONEMIZE_VERSION/g $src_dir/package-optional.json
sed -i.bak s/PLATFORM2/$platform2/g $src_dir/package-optional.json
sed -i.bak s/PLATFORM/$platform/g $src_dir/package-optional.json
sed -i.bak s/ARCH/$arch/g $src_dir/package-optional.json

git diff $src_dir/package-optional.json

dst=$piper_phonemize_dir/piper-phonemize-${platform2}-${arch}
mkdir -p $dst

cp $src_dir/package-optional.json $dst/package.json
cp $src_dir/index.js $dst/
cp $src_dir/README-optional.md $dst/README.md

cp -fv build/install/lib/lib* $dst/ || true
cp -fv build/install/lib/*dll $dst/ || true

cp scripts/node-addon-api/build/Release/piper-phonemize.node $dst/

ls $dst
