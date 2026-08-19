#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

old_version="1\.4\.6"
new_version="1\.4\.7"

replace_str="s/$old_version/$new_version/g"

sed -i.bak "$replace_str" ./CMakeLists.txt
sed -i.bak "$replace_str" ./src/c-api.h
sed -i.bak "$replace_str" ./build-macos.sh
sed -i.bak "$replace_str" ./build-macos-shared.sh
sed -i.bak "$replace_str" ./build-ios.sh
sed -i.bak "$replace_str" ./build-ios-shared.sh
sed -i.bak "$replace_str" ./Package.swift
sed -i.bak "$replace_str" ./src/c-api.cpp
sed -i.bak "$replace_str" ./pom.xml
sed -i.bak "$replace_str" ./jitpack.yml
sed -i.bak "$replace_str" ./java-api/pom.xml
sed -i.bak "$replace_str" ./java-api-examples/maven-examples/pom.xml
sed -i.bak "$replace_str" ./java-api-examples/gradle-examples/build.gradle
sed -i.bak "$replace_str" ./java-api-examples/gradle-kts-examples/build.gradle.kts
sed -i.bak "$replace_str" ./android-demo/app/build.gradle.kts
sed -i.bak "$replace_str" ./go-api-examples/go.mod
sed -i.bak "$replace_str" ./go-api-examples/README.md
sed -i.bak "$replace_str" ./scripts/npm/package.json
sed -i.bak "$replace_str" ./nodejs-examples/package.json
sed -i.bak "$replace_str" ./nodejs-addon-examples/package.json
sed -i.bak "$replace_str" ./rust/piper-phonemize-sys/Cargo.toml
sed -i.bak "$replace_str" ./rust/piper-phonemize/Cargo.toml
sed -i.bak "$replace_str" ./rust-api-examples/Cargo.toml
sed -i.bak "$replace_str" ./tauri-examples/src-tauri/tauri.conf.json
sed -i.bak "$replace_str" ./tauri-examples/src-tauri/Cargo.toml

sed -i.bak "$replace_str" ./scripts/dotnet/PiperPhonemize.csproj.in
sed -i.bak "$replace_str" ./scripts/dotnet/PiperPhonemize.Runtime.csproj.in

sed -i.bak "$replace_str" ./.github/workflows/build-wheel-macos-arm64.yaml

find ./.github/workflows -name "*.yaml" -type f -exec sed -i.bak "s/$old_version/$new_version/g" {} \;

find . -name "*.bak" -exec rm {} \;
