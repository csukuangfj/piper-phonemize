#!/usr/bin/env bash

set -ex

git config --global user.email "csukuangfj@gmail.com"
git config --global user.name "Fangjun Kuang"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PIPER_PHONEMIZE_DIR=$(realpath $SCRIPT_DIR/../..)
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "PIPER_PHONEMIZE_DIR: $PIPER_PHONEMIZE_DIR"

PIPER_PHONEMIZE_VERSION=$(grep "set(PIPER_PHONEMIZE_VERSION" $PIPER_PHONEMIZE_DIR/CMakeLists.txt | sed 's/.*set(PIPER_PHONEMIZE_VERSION \(.*\))/\1/' | tr -d ' ")')
echo "PIPER_PHONEMIZE_VERSION $PIPER_PHONEMIZE_VERSION"

GITHUB_RELEASE_URL="https://github.com/csukuangfj/piper-phonemize/releases/download/v${PIPER_PHONEMIZE_VERSION}"

GO_PROXY_WAIT_SECS=30
GO_PROXY_MAX_RETRIES=40

# Shared libs are extracted from these wheels. Keep the names in sync with the
# artifacts uploaded by the build-wheels-* workflows.
WHEEL_LINUX_X86_64="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-manylinux2014_x86_64.manylinux_2_17_x86_64.whl"
WHEEL_LINUX_AARCH64="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-manylinux2014_aarch64.manylinux_2_17_aarch64.whl"
WHEEL_LINUX_ARMV7="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-manylinux_2_31_armv7l.whl"
WHEEL_MACOS_X86_64="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-macosx_10_14_x86_64.whl"
WHEEL_MACOS_ARM64="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-macosx_11_0_arm64.whl"
WHEEL_WIN_AMD64="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-win_amd64.whl"
WHEEL_WIN_X86="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp310-cp310-win32.whl"
# win_arm64 is only built for cp311+ (no cp310 wheel exists), so use cp311 here.
# Only the bundled DLLs matter to Go, not the Python ABI.
WHEEL_WIN_ARM64="piper_phonemize-${PIPER_PHONEMIZE_VERSION}-cp311-cp311-win_arm64.whl"

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
#
# Exits with a non-zero status if the wheel cannot be downloaded, is not a
# valid zip, or yields no shared libs. Never skip a failed download: that
# publishes an empty lib/ directory to Go users.
download_libs() {
  local wheel_name="$1"
  local dst="$2"
  local filter="${3:-}"
  local url="${GITHUB_RELEASE_URL}/${wheel_name}"

  echo "Downloading $url ..."

  # Always start from a clean directory so a previous release's libs cannot
  # leak into this one when a download fails or extracts nothing.
  rm -rf "$dst"
  mkdir -p "$dst"

  local workdir
  workdir=$(mktemp -d)

  if ! curl --fail -L -o "$workdir/wheel.whl" "$url"; then
    echo "ERROR: failed to download $wheel_name from $url"
    echo "ERROR: the wheel may still be building; re-run this workflow once it is published"
    rm -rf "$workdir"
    exit 1
  fi

  if ! unzip -q -o "$workdir/wheel.whl" -d "$workdir/x"; then
    echo "ERROR: $wheel_name is not a valid wheel/zip"
    rm -rf "$workdir"
    exit 1
  fi

  # Copy shared libs from the wheel
  if [ "$filter" = "win32" ]; then
    # For Windows MSVC wheels: only copy non-prefixed DLLs (piper_phonemize_*.dll)
    # and their import libraries (.lib)
    find "$workdir/x" -name "piper_phonemize_*.dll" -o -name "piper_phonemize_*.lib" -o -name "espeak-ng.lib" -o -name "ucd.lib" | while read f; do
      cp -v "$f" "$dst/"
    done
  else
    # Copy shared libs but exclude Python extension modules (*.cpython-*.so)
    find "$workdir/x" \( -name "*.so" -o -name "*.dylib" -o -name "*.dll" \) ! -name "*.cpython-*" | while read f; do
      cp -v "$f" "$dst/"
    done
  fi
  rm -rf "$workdir"

  if [ -z "$(ls -A "$dst" 2>/dev/null)" ]; then
    echo "ERROR: no shared libs extracted from $wheel_name into $dst"
    echo "ERROR: refusing to publish an empty lib/ directory"
    exit 1
  fi

  echo "Extracted libs from $wheel_name into $dst:"
  ls -l "$dst"
}

# Fail unless every listed lib subdirectory of <pkg_dir>/lib exists and is
# non-empty. This is the last gate before pushing a package.
# Usage: assert_libs_present <pkg_dir> <lib_subdir> [<lib_subdir> ...]
assert_libs_present() {
  local pkg_dir="$1"
  shift
  local sub

  for sub in "$@"; do
    if [ -z "$(ls -A "$pkg_dir/lib/$sub" 2>/dev/null)" ]; then
      echo "ERROR: $pkg_dir/lib/$sub is missing or empty"
      echo "ERROR: refusing to publish an incomplete Go package"
      exit 1
    fi
    echo "OK: $pkg_dir/lib/$sub ->"
    ls -l "$pkg_dir/lib/$sub"
  done
}

# Commit, push and tag a Go package. Every step must succeed: a failure
# swallowed here means a broken or untagged module is silently published.
publish_go_package() {
  local pkg_dir="$1"
  local pkg_url="$2"

  cd "$pkg_dir"
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION"
  git push
  git tag v$PIPER_PHONEMIZE_VERSION
  git push origin v$PIPER_PHONEMIZE_VERSION
  cd ..
  kick_go_proxy "$pkg_url" "v$PIPER_PHONEMIZE_VERSION"
}

# Download espeak-ng-data if not already present.
download_espeak_ng_data() {
  if [ ! -d "$PIPER_PHONEMIZE_DIR/espeak-ng-data" ]; then
    echo "Downloading espeak-ng-data..."
    cd "$PIPER_PHONEMIZE_DIR"
    curl --fail -L -o espeak-ng-data.tar.bz2 \
      https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2
    tar xvf espeak-ng-data.tar.bz2
    rm -f espeak-ng-data.tar.bz2
    cd -
  fi
}

function linux() {
  echo "Process linux"
  git clone git@github.com:csukuangfj/piper-phonemize-go-linux.git

  rm -v ./piper-phonemize-go-linux/*.go || true

  cp -v ./piper_phonemize.go ./piper-phonemize-go-linux/
  cp -v "$PIPER_PHONEMIZE_DIR/src/c-api.h" ./piper-phonemize-go-linux/
  cp -v ./build_linux_*.go ./piper-phonemize-go-linux/

  # Create go.mod
  cat > piper-phonemize-go-linux/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-linux

go 1.17
GOMOD

  # Download and extract libs from wheels
  rm -rf piper-phonemize-go-linux/lib/x86_64-unknown-linux-gnu
  mkdir -p piper-phonemize-go-linux/lib/x86_64-unknown-linux-gnu
  download_libs \
    "$WHEEL_LINUX_X86_64" \
    "$(realpath piper-phonemize-go-linux/lib/x86_64-unknown-linux-gnu)"

  rm -rf piper-phonemize-go-linux/lib/aarch64-unknown-linux-gnu
  mkdir -p piper-phonemize-go-linux/lib/aarch64-unknown-linux-gnu
  download_libs \
    "$WHEEL_LINUX_AARCH64" \
    "$(realpath piper-phonemize-go-linux/lib/aarch64-unknown-linux-gnu)"

  rm -rf piper-phonemize-go-linux/lib/arm-unknown-linux-gnueabihf
  mkdir -p piper-phonemize-go-linux/lib/arm-unknown-linux-gnueabihf
  download_libs \
    "$WHEEL_LINUX_ARMV7" \
    "$(realpath piper-phonemize-go-linux/lib/arm-unknown-linux-gnueabihf)"

  assert_libs_present piper-phonemize-go-linux \
    x86_64-unknown-linux-gnu \
    aarch64-unknown-linux-gnu \
    arm-unknown-linux-gnueabihf

  echo "------------------------------"
  publish_go_package piper-phonemize-go-linux "github.com/csukuangfj/piper-phonemize-go-linux"
  rm -rf piper-phonemize-go-linux
}

function osx() {
  echo "Process osx"
  git clone git@github.com:csukuangfj/piper-phonemize-go-macos.git
  rm -v ./piper-phonemize-go-macos/*.go || true
  cp -v ./piper_phonemize.go ./piper-phonemize-go-macos/
  cp -v "$PIPER_PHONEMIZE_DIR/src/c-api.h" ./piper-phonemize-go-macos/
  cp -v ./build_darwin_*.go ./piper-phonemize-go-macos/

  # Create go.mod
  cat > piper-phonemize-go-macos/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-macos

go 1.17
GOMOD

  # Download and extract libs from wheels
  rm -rf piper-phonemize-go-macos/lib/x86_64-apple-darwin
  mkdir -p piper-phonemize-go-macos/lib/x86_64-apple-darwin
  download_libs \
    "$WHEEL_MACOS_X86_64" \
    "$(realpath piper-phonemize-go-macos/lib/x86_64-apple-darwin)"

  rm -rf piper-phonemize-go-macos/lib/aarch64-apple-darwin
  mkdir -p piper-phonemize-go-macos/lib/aarch64-apple-darwin
  download_libs \
    "$WHEEL_MACOS_ARM64" \
    "$(realpath piper-phonemize-go-macos/lib/aarch64-apple-darwin)"

  assert_libs_present piper-phonemize-go-macos \
    x86_64-apple-darwin \
    aarch64-apple-darwin

  echo "------------------------------"
  publish_go_package piper-phonemize-go-macos "github.com/csukuangfj/piper-phonemize-go-macos"
  rm -rf piper-phonemize-go-macos
}

function windows() {
  echo "Process windows"
  git clone git@github.com:csukuangfj/piper-phonemize-go-windows.git
  rm -v ./piper-phonemize-go-windows/*.go || true
  cp -v ./piper_phonemize.go ./piper-phonemize-go-windows/
  cp -v "$PIPER_PHONEMIZE_DIR/src/c-api.h" ./piper-phonemize-go-windows/
  cp -v ./build_windows_*.go ./piper-phonemize-go-windows/

  # Create go.mod
  cat > piper-phonemize-go-windows/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-windows

go 1.17
GOMOD

  # Download and extract libs from wheels
  # Use "win32" filter to only copy MSVC-built DLLs (no lib prefix)
  rm -rf piper-phonemize-go-windows/lib/x86_64-pc-windows-gnu
  mkdir -p piper-phonemize-go-windows/lib/x86_64-pc-windows-gnu
  download_libs \
    "$WHEEL_WIN_AMD64" \
    "$(realpath piper-phonemize-go-windows/lib/x86_64-pc-windows-gnu)" \
    "win32"

  rm -rf piper-phonemize-go-windows/lib/i686-pc-windows-gnu
  mkdir -p piper-phonemize-go-windows/lib/i686-pc-windows-gnu
  download_libs \
    "$WHEEL_WIN_X86" \
    "$(realpath piper-phonemize-go-windows/lib/i686-pc-windows-gnu)" \
    "win32"

  rm -rf piper-phonemize-go-windows/lib/aarch64-pc-windows-gnu
  mkdir -p piper-phonemize-go-windows/lib/aarch64-pc-windows-gnu
  download_libs \
    "$WHEEL_WIN_ARM64" \
    "$(realpath piper-phonemize-go-windows/lib/aarch64-pc-windows-gnu)" \
    "win32"

  assert_libs_present piper-phonemize-go-windows \
    x86_64-pc-windows-gnu \
    i686-pc-windows-gnu \
    aarch64-pc-windows-gnu

  echo "------------------------------"
  publish_go_package piper-phonemize-go-windows "github.com/csukuangfj/piper-phonemize-go-windows"
  rm -rf piper-phonemize-go-windows
}

function basic() {
  echo "Process piper-phonemize-go"
  git clone git@github.com:csukuangfj/piper-phonemize-go.git

  python3 ./generate.py -s ./piper_phonemize.go -o ./piper-phonemize-go

  # Bundle espeak-ng-data into the facade package
  download_espeak_ng_data
  cp -rv "$PIPER_PHONEMIZE_DIR/espeak-ng-data" ./piper-phonemize-go/piper_phonemize/
  cp -v "$SCRIPT_DIR/espeak_ng_data.go" ./piper-phonemize-go/piper_phonemize/

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
  publish_go_package piper-phonemize-go "github.com/csukuangfj/piper-phonemize-go"
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
