//go:build !android && linux && arm64

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/aarch64-unknown-linux-gnu -lpiper_phonemize_core -Wl,-rpath,${SRCDIR}/lib/aarch64-unknown-linux-gnu
import "C"
