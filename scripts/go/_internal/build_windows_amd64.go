//go:build windows && amd64

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/x86_64-pc-windows-gnu -lpiper_phonemize_core
import "C"
