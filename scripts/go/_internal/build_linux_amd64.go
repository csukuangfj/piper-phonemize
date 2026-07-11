//go:build !android && linux && amd64 && !musl

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/x86_64-unknown-linux-gnu -lpiper_phonemize_core -Wl,-rpath,${SRCDIR}/lib/x86_64-unknown-linux-gnu
import "C"
