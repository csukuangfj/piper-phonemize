//go:build darwin && arm64 && !ios

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/aarch64-apple-darwin -lpiper_phonemize_core -Wl,-rpath,${SRCDIR}/lib/aarch64-apple-darwin
import "C"
