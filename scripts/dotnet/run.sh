#!/usr/bin/env bash
# Copyright (c) 2026  Xiaomi Corporation
#
# Build NuGet packages for piper-phonemize.
#
# Usage:
#   ./scripts/dotnet/run.sh
#
# Prerequisites:
#   Native shared libs must be available in /tmp/dotnet/$rid/
#   (downloaded from CI artifacts or built locally)

set -ex

cd "$(dirname "$0")/../.."

VERSION=$(grep "set(PIPER_PHONEMIZE_VERSION" ./CMakeLists.txt | sed 's/.*set(PIPER_PHONEMIZE_VERSION \(.*\))/\1/' | tr -d ' ")')
echo "VERSION=$VERSION"

OUT_DIR=/tmp/dotnet
PACKAGES_DIR=$OUT_DIR/packages

rm -rf $PACKAGES_DIR
mkdir -p $PACKAGES_DIR

# List of RIDs
RIDS="linux-x64 linux-arm64 android-arm64 android-x64 osx-x64 osx-arm64 win-x64 win-arm64"

# Generate .csproj files
python3 ./scripts/dotnet/generate.py "$VERSION" "$OUT_DIR"

# Build and pack each runtime package
for rid in $RIDS; do
  rid_dir=$OUT_DIR/$rid
  if [ ! -f "$rid_dir/PiperPhonemize.Runtime.csproj" ]; then
    echo "WARNING: No csproj for $rid, skipping"
    continue
  fi

  echo "=== Packing runtime: $rid ==="
  dotnet pack "$rid_dir/PiperPhonemize.Runtime.csproj" -c Release -o $PACKAGES_DIR
done

# Build and pack the common (metapackage) package
echo "=== Packing common package ==="
dotnet pack "$OUT_DIR/all/PiperPhonemize.csproj" -c Release -o $PACKAGES_DIR

echo ""
echo "=== Packages ==="
ls -lh $PACKAGES_DIR/*.nupkg
