//go:build !android && linux && arm

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/arm-unknown-linux-gnueabihf -lpiper_phonemize_core -Wl,-rpath,${SRCDIR}/lib/arm-unknown-linux-gnueabihf
import "C"
