#!/usr/bin/env bash

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

pushd "$SCRIPT_DIR/piper-phonemize-sys"
cp -v "$PROJECT_DIR/README.md" ./
cp -v "$PROJECT_DIR/LICENSE.md" ./
popd

pushd "$SCRIPT_DIR/piper-phonemize"
cp -v "$PROJECT_DIR/README.md" ./
cp -v "$PROJECT_DIR/LICENSE.md" ./
popd
