//go:build windows && arm64

package piper_phonemize

// #cgo LDFLAGS: -L ${SRCDIR}/lib/aarch64-pc-windows-gnu -lpiper_phonemize_core
import "C"
