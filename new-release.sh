#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

old_version="1\.4\.6"
new_version="1\.4\.7"

replace_str="s/$old_version/$new_version/g"

sed -i.bak "$replace_str" ./CMakeLists.txt
sed -i.bak "$replace_str" ./src/c-api.h
sed -i.bak "$replace_str" ./src/c-api.cpp
sed -i.bak "$replace_str" ./go-api-examples/go.mod
sed -i.bak "$replace_str" ./go-api-examples/README.md
sed -i.bak "$replace_str" ./scripts/npm/package.json
sed -i.bak "$replace_str" ./nodejs-examples/package.json
sed -i.bak "$replace_str" ./nodejs-addon-examples/package.json
sed -i.bak "$replace_str" ./rust/piper-phonemize-sys/Cargo.toml
sed -i.bak "$replace_str" ./rust/piper-phonemize/Cargo.toml
sed -i.bak "$replace_str" ./rust-api-examples/Cargo.toml

sed -i.bak "$replace_str" ./.github/workflows/build-wheel-macos-arm64.yaml

find ./.github/workflows -name "build-wheel-*.yaml" -type f -exec sed -i.bak "s/$old_version/$new_version/g" {} \;

find . -name "*.bak" -exec rm {} \;
