#!/usr/bin/env bash

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

source ./setup.sh

java \
  -cp "../java-api/target/piper-phonemize-jvm-1.4.7.jar" \
  -Dpiper_phonemize.native.path=../build-jni/install/lib \
  PhonemizeText.java
