#!/usr/bin/env bash
#
# Run the Dart hello_world example.
#
# Usage:
#   cd dart-api-examples/hello_world
#   bash run.sh [/path/to/espeak-ng-data]
#
# If no path is given, uses ../../swift-api-examples/espeak-ng-data

set -ex

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)

ESPEAK_DATA_DIR="${1:-$PROJECT_DIR/swift-api-examples/espeak-ng-data}"

cd "$SCRIPT_DIR"
dart run bin/main.dart "$ESPEAK_DATA_DIR"
