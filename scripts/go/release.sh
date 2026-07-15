#!/usr/bin/env bash

set -ex

git config --global user.email "csukuangfj@gmail.com"
git config --global user.name "Fangjun Kuang"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PIPER_PHONEMIZE_DIR=$(realpath $SCRIPT_DIR/../..)
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "PIPER_PHONEMIZE_DIR: $PIPER_PHONEMIZE_DIR"

PIPER_PHONEMIZE_VERSION=$(grep "project(" $PIPER_PHONEMIZE_DIR/CMakeLists.txt -A 3 | grep "VERSION" | head -1 | awk '{print $2}')
echo "PIPER_PHONEMIZE_VERSION $PIPER_PHONEMIZE_VERSION"

GITHUB_RELEASE_URL="https://github.com/csukuangfj/piper-phonemize/releases/download/v${PIPER_PHONEMIZE_VERSION}"

GO_PROXY_WAIT_SECS=30
GO_PROXY_MAX_RETRIES=40

# Proactively tell the Go module proxy to fetch a specific version.
kick_go_proxy() {
  local pkg="$1"
  local version="$2"
  echo "Kicking Go proxy to fetch $pkg@$version ..."
  curl -sS "https://proxy.golang.org/${pkg}/@v/${version}.info" || true
  echo ""
}

# Wait for Go module proxy to index newly published packages.
wait_for_go_proxy() {
  local pkg="$1"
  local version="$2"
  local i

  kick_go_proxy "$pkg" "$version"

  for i in $(seq 1 $GO_PROXY_MAX_RETRIES); do
    echo "Attempt $i/$GO_PROXY_MAX_RETRIES: checking $pkg@$version ..."
    if curl -sS -o /dev/null -w "%{http_code}" "https://proxy.golang.org/${pkg}/@v/${version}.info" | grep -q "200"; then
      echo "  -> $pkg@$version is available on Go proxy"
      return 0
    fi
    echo "  -> not ready yet, sleeping ${GO_PROXY_WAIT_SECS}s ..."
    sleep $GO_PROXY_WAIT_SECS
  done
  echo "ERROR: $pkg@$version not available after $GO_PROXY_MAX_RETRIES attempts"
  return 1
}

# Run go mod tidy with retries.
run_go_mod_tidy() {
  local i
  for i in $(seq 1 $GO_PROXY_MAX_RETRIES); do
    echo "Attempt $i/$GO_PROXY_MAX_RETRIES: running go mod tidy ..."
    if go mod tidy 2>&1; then
      echo "  -> go mod tidy succeeded"
      return 0
    fi
    echo "  -> go mod tidy failed, sleeping ${GO_PROXY_WAIT_SECS}s ..."
    sleep $GO_PROXY_WAIT_SECS
  done
  echo "ERROR: go mod tidy failed after $GO_PROXY_MAX_RETRIES attempts"
  return 1
}

# Download a wheel, extract shared libs, and copy to destination.
# Usage: download_libs <wheel_filename> <dst_dir> [filter]
# filter: "win32" to only copy non-prefixed DLLs (for MSVC-built wheels)
download_libs() {
  local wheel_name="$1"
  local dst="$2"
  local filter="${3:-}"
  local url="${GITHUB_RELEASE_URL}/${wheel_name}"

  echo "Downloading $url ..."
  mkdir -p t && cd t
  curl -L -o wheel.whl "$url"

  # Check if download was successful (file should be > 100 bytes)
  if [ ! -f wheel.whl ] || [ $(stat -c%s wheel.whl 2>/dev/null || stat -f%z wheel.whl 2>/dev/null || echo 0) -lt 100 ]; then
    echo "WARNING: Failed to download $wheel_name, skipping"
    cd ..
    rm -rf t
    return 0
  fi

  unzip -o wheel.whl

  # Copy shared libs from the wheel
  if [ "$filter" = "win32" ]; then
    # For Windows MSVC wheels: only copy non-prefixed DLLs (piper_phonemize_*.dll)
    # and their import libraries (.lib)
    find . -name "piper_phonemize_*.dll" -o -name "piper_phonemize_*.lib" -o -name "espeak-ng.lib" -o -name "ucd.lib" | while read f; do
      cp -v "$f" "$dst/"
    done
  else
    find . -name "*.so" -o -name "*.dylib" -o -name "*.dll" | while read f; do
      cp -v "$f" "$dst/"
    done
  fi

  cd ..
  rm -rf t
}

function linux() {
  echo "Process linux"
  git clone git@github.com:csukuangfj/piper-phonemize-go-linux.git

  rm -v ./piper-phonemize-go-linux/*.go || true

  cp -v ./piper_phonemize.go ./piper-phonemize-go-linux/
  cp -v ./_internal/c-api.h ./piper-phonemize-go-linux/
  cp -v ./build_linux_*.go ./piper-phonemize-go-linux/

  # Create go.mod
  cat > piper-phonemize-go-linux/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-linux

go 1.17
GOMOD

  # Download and extract libs from wheels
  mkdir -p piper-phonemize-go-linux/lib/x86_64-unknown-linux-gnu
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-manylinux2014_x86_64.manylinux_2_17_x86_64.whl" \
    "$(realpath piper-phonemize-go-linux/lib/x86_64-unknown-linux-gnu)"

  mkdir -p piper-phonemize-go-linux/lib/aarch64-unknown-linux-gnu
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-manylinux2014_aarch64.manylinux_2_17_aarch64.whl" \
    "$(realpath piper-phonemize-go-linux/lib/aarch64-unknown-linux-gnu)"

  mkdir -p piper-phonemize-go-linux/lib/arm-unknown-linux-gnueabihf
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-manylinux_2_31_armv7l.whl" \
    "$(realpath piper-phonemize-go-linux/lib/arm-unknown-linux-gnueabihf)"

  echo "------------------------------"
  cd piper-phonemize-go-linux
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
  git push && \
  git tag v$PIPER_PHONEMIZE_VERSION && \
  git push origin v$PIPER_PHONEMIZE_VERSION || true
  cd ..
  kick_go_proxy "github.com/csukuangfj/piper-phonemize-go-linux" "v$PIPER_PHONEMIZE_VERSION"
  rm -rf piper-phonemize-go-linux
}

function osx() {
  echo "Process osx"
  git clone git@github.com:csukuangfj/piper-phonemize-go-macos.git
  rm -v ./piper-phonemize-go-macos/*.go || true
  cp -v ./piper_phonemize.go ./piper-phonemize-go-macos/
  cp -v ./_internal/c-api.h ./piper-phonemize-go-macos/
  cp -v ./build_darwin_*.go ./piper-phonemize-go-macos/

  # Create go.mod
  cat > piper-phonemize-go-macos/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-macos

go 1.17
GOMOD

  # Download and extract libs from wheels
  mkdir -p piper-phonemize-go-macos/lib/x86_64-apple-darwin
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-macosx_10_14_x86_64.whl" \
    "$(realpath piper-phonemize-go-macos/lib/x86_64-apple-darwin)"

  mkdir -p piper-phonemize-go-macos/lib/aarch64-apple-darwin
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-macosx_11_0_arm64.whl" \
    "$(realpath piper-phonemize-go-macos/lib/aarch64-apple-darwin)"

  echo "------------------------------"
  cd piper-phonemize-go-macos
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
  git push && \
  git tag v$PIPER_PHONEMIZE_VERSION && \
  git push origin v$PIPER_PHONEMIZE_VERSION || true
  cd ..
  kick_go_proxy "github.com/csukuangfj/piper-phonemize-go-macos" "v$PIPER_PHONEMIZE_VERSION"
  rm -rf piper-phonemize-go-macos
}

function windows() {
  echo "Process windows"
  git clone git@github.com:csukuangfj/piper-phonemize-go-windows.git
  rm -v ./piper-phonemize-go-windows/*.go || true
  cp -v ./piper_phonemize.go ./piper-phonemize-go-windows/
  cp -v ./_internal/c-api.h ./piper-phonemize-go-windows/
  cp -v ./build_windows_*.go ./piper-phonemize-go-windows/

  # Create go.mod
  cat > piper-phonemize-go-windows/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-windows

go 1.17
GOMOD

  # Download and extract libs from wheels
  # Use "win32" filter to only copy MSVC-built DLLs (no lib prefix)
  mkdir -p piper-phonemize-go-windows/lib/x86_64-pc-windows-gnu
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-win_amd64.whl" \
    "$(realpath piper-phonemize-go-windows/lib/x86_64-pc-windows-gnu)" \
    "win32"

  mkdir -p piper-phonemize-go-windows/lib/i686-pc-windows-gnu
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-win32.whl" \
    "$(realpath piper-phonemize-go-windows/lib/i686-pc-windows-gnu)" \
    "win32"

  mkdir -p piper-phonemize-go-windows/lib/aarch64-pc-windows-gnu
  download_libs \
    "piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-win_arm64.whl" \
    "$(realpath piper-phonemize-go-windows/lib/aarch64-pc-windows-gnu)" \
    "win32"

  echo "------------------------------"
  cd piper-phonemize-go-windows
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
  git push && \
  git tag v$PIPER_PHONEMIZE_VERSION && \
  git push origin v$PIPER_PHONEMIZE_VERSION || true
  cd ..
  kick_go_proxy "github.com/csukuangfj/piper-phonemize-go-windows" "v$PIPER_PHONEMIZE_VERSION"
  rm -rf piper-phonemize-go-windows
}

function basic() {
  echo "Process piper-phonemize-go"
  git clone git@github.com:csukuangfj/piper-phonemize-go.git

  python3 ./generate.py -s ./piper_phonemize.go -o ./piper-phonemize-go

  cd piper-phonemize-go

  local ver="v$PIPER_PHONEMIZE_VERSION"

  # Create go.mod
  cat > go.mod << GOMOD
module github.com/csukuangfj/piper-phonemize-go

go 1.17

require (
	github.com/csukuangfj/piper-phonemize-go-linux v$PIPER_PHONEMIZE_VERSION
	github.com/csukuangfj/piper-phonemize-go-macos v$PIPER_PHONEMIZE_VERSION
	github.com/csukuangfj/piper-phonemize-go-windows v$PIPER_PHONEMIZE_VERSION
)
GOMOD
  rm -f go.mod.bak

  echo "--- Updated go.mod ---"
  cat go.mod
  echo "--- end go.mod ---"

  # Wait for the Go module proxy to index all three platform packages
  local pkg
  for pkg in piper-phonemize-go-linux piper-phonemize-go-macos piper-phonemize-go-windows; do
    wait_for_go_proxy "github.com/csukuangfj/$pkg" "$ver"
  done

  rm -f go.sum
  run_go_mod_tidy

  echo "--- Updated go.sum ---"
  cat go.sum
  echo "--- end go.sum ---"

  cd ..

  echo "------------------------------"
  cd piper-phonemize-go
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
    git push && \
    git tag v$PIPER_PHONEMIZE_VERSION && \
    git push origin v$PIPER_PHONEMIZE_VERSION
  cd ..
  rm -rf piper-phonemize-go
}

# Publishing order matters:
#   1. Platform packages first (linux, windows, osx) — they have no inter-dependencies
#   2. Wait for Go proxy to index them
#   3. piper-phonemize-go last — it depends on all three platform packages
linux
windows
osx
basic

rm -fv ~/.ssh/github
