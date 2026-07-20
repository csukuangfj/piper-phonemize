//go:build windows && 386

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/i686-pc-windows-gnu -lpiper_phonemize_core
import "C"
