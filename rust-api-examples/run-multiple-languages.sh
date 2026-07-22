#!/usr/bin/env bash

# Usage: ./run-multiple-languages.sh [static|shared]
#   static (default) - link against prebuilt static libraries
#   shared           - link against prebuilt shared libraries

set -ex

LINK=${1:-static}
cargo run --example multiple_languages --no-default-features --features "$LINK"
