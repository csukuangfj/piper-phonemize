#!/usr/bin/env bash
#
# Run the SPM example
#
# Usage:
#   cd spm-examples
#   bash run.sh

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Download espeak-ng-data if not present
if [ ! -d "$PROJECT_DIR/espeak-ng-data" ]; then
  echo "Downloading espeak-ng-data..."
  cd "$PROJECT_DIR"
  curl -OL https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
  tar xvf espeak-ng-data.tar.bz2
  rm -f espeak-ng-data.tar.bz2
fi

cd "$SCRIPT_DIR"

# Build and run using SPM
swift run piper-phonemize-example "$PROJECT_DIR/espeak-ng-data"
