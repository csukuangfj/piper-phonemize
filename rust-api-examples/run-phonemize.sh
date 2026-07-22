#!/usr/bin/env bash

# Usage: ./run-phonemize.sh [static|shared]
#   static (default) - link against prebuilt static libraries
#   shared           - link against prebuilt shared libraries

set -ex

LINK=${1:-static}
cargo run --example phonemize --no-default-features --features "$LINK"
