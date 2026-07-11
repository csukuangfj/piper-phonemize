//go:build darwin && amd64 && !ios

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/x86_64-apple-darwin -lpiper_phonemize_core -Wl,-rpath,${SRCDIR}/lib/x86_64-apple-darwin
import "C"
