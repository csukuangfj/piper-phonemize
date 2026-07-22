#!/usr/bin/env bash

# Usage: ./run.sh [static|shared]
#   static (default) - link against prebuilt static libraries
#   shared           - link against prebuilt shared libraries

set -ex

cd "$(dirname "$0")"

LINK=${1:-static}
cargo tauri dev --features "$LINK"
