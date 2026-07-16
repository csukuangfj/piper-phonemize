#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

old_version="1\.4\.5"
new_version="1\.4\.6"

replace_str="s/$old_version/$new_version/g"

sed -i.bak "$replace_str" ./CMakeLists.txt
sed -i.bak "$replace_str" ./csrc/c-api.h
sed -i.bak "$replace_str" ./csrc/c-api.cpp
sed -i.bak "$replace_str" ./go-api-examples/go.mod
