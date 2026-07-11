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

# Wait for Go proxy to index newly published packages.
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

build_libs() {
  echo "Building piper-phonemize from source for $1"
  local build_dir=$PIPER_PHONEMIZE_DIR/build-go-$1
  cmake -B $build_dir -S $PIPER_PHONEMIZE_DIR \
    -DCMAKE_INSTALL_PREFIX=$build_dir/install \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    $2
  cmake --build $build_dir --config Release -j$(nproc)
  cmake --install $build_dir
}

function linux() {
  echo "Process linux"
  git clone git@github.com:csukuangfj/piper-phonemize-go-linux.git

  rm -v ./piper-phonemize-go-linux/*.go || true

  cp -v ./piper_phonemize.go ./piper-phonemize-go-linux/
  cp -v ./_internal/c-api.h ./piper-phonemize-go-linux/
  cp -v ./build_linux_*.go ./piper-phonemize-go-linux/

  # Create go.mod with v2 module path
  cat > piper-phonemize-go-linux/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-linux/v2

go 1.17
GOMOD

  # Create lib directories
  mkdir -p piper-phonemize-go-linux/lib/{x86_64-unknown-linux-gnu,aarch64-unknown-linux-gnu,arm-unknown-linux-gnueabihf}

  # Build for x86_64
  build_libs linux-x86_64 "-DCMAKE_SYSTEM_NAME=Linux"
  dst=$(realpath piper-phonemize-go-linux/lib/x86_64-unknown-linux-gnu)
  rm -fv $dst/lib*
  cp -v $PIPER_PHONEMIZE_DIR/build-go-linux-x86_64/install/lib/libpiper_phonemize* $dst/

  # Build for aarch64 (cross-compile if possible, otherwise use native)
  if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    build_libs linux-aarch64 "-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++"
    dst=$(realpath piper-phonemize-go-linux/lib/aarch64-unknown-linux-gnu)
    rm -fv $dst/lib*
    cp -v $PIPER_PHONEMIZE_DIR/build-go-linux-aarch64/install/lib/libpiper_phonemize* $dst/
  fi

  # Build for armv7 (cross-compile if possible, otherwise use native)
  if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    build_libs linux-armv7 "-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++"
    dst=$(realpath piper-phonemize-go-linux/lib/arm-unknown-linux-gnueabihf)
    rm -fv $dst/lib*
    cp -v $PIPER_PHONEMIZE_DIR/build-go-linux-armv7/install/lib/libpiper_phonemize* $dst/
  fi

  echo "------------------------------"
  cd piper-phonemize-go-linux
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
  git push && \
  git tag v$PIPER_PHONEMIZE_VERSION && \
  git push origin v$PIPER_PHONEMIZE_VERSION || true
  cd ..
  kick_go_proxy "github.com/csukuangfj/piper-phonemize-go-linux/v2" "v$PIPER_PHONEMIZE_VERSION"
  rm -rf piper-phonemize-go-linux
}

function osx() {
  echo "Process osx"
  git clone git@github.com:csukuangfj/piper-phonemize-go-macos.git
  rm -v ./piper-phonemize-go-macos/*.go || true
  cp -v ./piper_phonemize.go ./piper-phonemize-go-macos/
  cp -v ./_internal/c-api.h ./piper-phonemize-go-macos/
  cp -v ./build_darwin_*.go ./piper-phonemize-go-macos/

  # Create go.mod with v2 module path
  cat > piper-phonemize-go-macos/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-macos/v2

go 1.17
GOMOD

  # Create lib directories
  mkdir -p piper-phonemize-go-macos/lib/{x86_64-apple-darwin,aarch64-apple-darwin}

  # Build for x86_64
  build_libs osx-x86_64 "-DCMAKE_OSX_ARCHITECTURES=x86_64"
  dst=$(realpath piper-phonemize-go-macos/lib/x86_64-apple-darwin/)
  rm -fv $dst/lib*
  cp -v $PIPER_PHONEMIZE_DIR/build-go-osx-x86_64/install/lib/libpiper_phonemize* $dst/

  # Build for arm64
  build_libs osx-arm64 "-DCMAKE_OSX_ARCHITECTURES=arm64"
  dst=$(realpath piper-phonemize-go-macos/lib/aarch64-apple-darwin)
  rm -fv $dst/lib*
  cp -v $PIPER_PHONEMIZE_DIR/build-go-osx-arm64/install/lib/libpiper_phonemize* $dst/

  echo "------------------------------"
  cd piper-phonemize-go-macos
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
  git push && \
  git tag v$PIPER_PHONEMIZE_VERSION && \
  git push origin v$PIPER_PHONEMIZE_VERSION || true
  cd ..
  kick_go_proxy "github.com/csukuangfj/piper-phonemize-go-macos/v2" "v$PIPER_PHONEMIZE_VERSION"
  rm -rf piper-phonemize-go-macos
}

function windows() {
  echo "Process windows"
  git clone git@github.com:csukuangfj/piper-phonemize-go-windows.git
  rm -v ./piper-phonemize-go-windows/*.go || true
  cp -v ./piper_phonemize.go ./piper-phonemize-go-windows/
  cp -v ./_internal/c-api.h ./piper-phonemize-go-windows/
  cp -v ./build_windows_*.go ./piper-phonemize-go-windows/

  # Create go.mod with v2 module path
  cat > piper-phonemize-go-windows/go.mod << 'GOMOD'
module github.com/csukuangfj/piper-phonemize-go-windows/v2

go 1.17
GOMOD

  # Create lib directories
  mkdir -p piper-phonemize-go-windows/lib/{x86_64-pc-windows-gnu,i686-pc-windows-gnu}

  # Windows cross-compilation from Linux using mingw
  if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    build_libs windows-x86_64 "-DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++"
    dst=$(realpath piper-phonemize-go-windows/lib/x86_64-pc-windows-gnu)
    rm -fv $dst/*
    cp -v $PIPER_PHONEMIZE_DIR/build-go-windows-x86_64/install/bin/*.dll $dst/ 2>/dev/null || true
    cp -v $PIPER_PHONEMIZE_DIR/build-go-windows-x86_64/install/lib/*.dll $dst/ 2>/dev/null || true
  fi

  if command -v i686-w64-mingw32-gcc &> /dev/null; then
    build_libs windows-i686 "-DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=i686-w64-mingw32-g++"
    dst=$(realpath piper-phonemize-go-windows/lib/i686-pc-windows-gnu)
    rm -fv $dst/*
    cp -v $PIPER_PHONEMIZE_DIR/build-go-windows-i686/install/bin/*.dll $dst/ 2>/dev/null || true
    cp -v $PIPER_PHONEMIZE_DIR/build-go-windows-i686/install/lib/*.dll $dst/ 2>/dev/null || true
  fi

  echo "------------------------------"
  cd piper-phonemize-go-windows
  git status
  git add .
  git commit -m "Release v$PIPER_PHONEMIZE_VERSION" && \
  git push && \
  git tag v$PIPER_PHONEMIZE_VERSION && \
  git push origin v$PIPER_PHONEMIZE_VERSION || true
  cd ..
  kick_go_proxy "github.com/csukuangfj/piper-phonemize-go-windows/v2" "v$PIPER_PHONEMIZE_VERSION"
  rm -rf piper-phonemize-go-windows
}

function basic() {
  echo "Process piper-phonemize-go"
  git clone git@github.com:csukuangfj/piper-phonemize-go.git

  python3 ./generate.py -s ./piper_phonemize.go -o ./piper-phonemize-go

  cd piper-phonemize-go

  # Create go.mod with v2 module path
  cat > go.mod << GOMOD
module github.com/csukuangfj/piper-phonemize-go/v2

go 1.17

require (
	github.com/csukuangfj/piper-phonemize-go-linux/v2 v$PIPER_PHONEMIZE_VERSION
	github.com/csukuangfj/piper-phonemize-go-macos/v2 v$PIPER_PHONEMIZE_VERSION
	github.com/csukuangfj/piper-phonemize-go-windows/v2 v$PIPER_PHONEMIZE_VERSION
)
GOMOD
  rm -f go.mod.bak

  echo "--- Updated go.mod ---"
  cat go.mod
  echo "--- end go.mod ---"

  # Wait for the Go module proxy to index all three platform packages
  local pkg
  for pkg in piper-phonemize-go-linux/v2 piper-phonemize-go-macos/v2 piper-phonemize-go-windows/v2; do
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
