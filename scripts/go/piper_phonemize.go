/*
Package piper_phonemize provides Go bindings for the piper-phonemize C API.

piper-phonemize is a phonemization library for the Piper text-to-speech system.
It uses espeak-ng to convert text into phoneme sequences.

It supports a variety of platforms, such as Linux (x86_64, aarch64, arm),
Windows (x86_64, x86), macOS (x86_64, arm64), etc.

Usage:

	import pp "github.com/csukuangfj/piper-phonemize-go/piper_phonemize"

	pp.Initialize("")  // uses embedded espeak-ng-data
	result := pp.Phonemize("hello world", "en-us")
	defer pp.DeletePhonemizeResult(result)
	for i := 0; i < result.GetNumSentences(); i++ {
		phonemes := result.GetPhonemes(i)
		// process phonemes
	}
*/
package piper_phonemize

// #include <stdlib.h>
// #include "c-api.h"
import "C"
import (
	"unsafe"
)

// PhonemizeResult holds the result of phonemization.
type PhonemizeResult struct {
	impl *C.PiperPhonemizeResult
}

// GetNumSentences returns the number of sentences in the result.
func (r *PhonemizeResult) GetNumSentences() int {
	return int(C.PiperPhonemizeResultGetNumSentences(r.impl))
}

// GetNumPhonemes returns the number of phonemes in a given sentence.
// Returns -1 if sentenceId is out of range.
func (r *PhonemizeResult) GetNumPhonemes(sentenceId int) int {
	return int(C.PiperPhonemizeResultGetNumPhonemes(r.impl, C.int32_t(sentenceId)))
}

// GetPhonemes returns the phonemes for a given sentence as a slice of Unicode
// code points (uint32). Returns nil if sentenceId is out of range.
func (r *PhonemizeResult) GetPhonemes(sentenceId int) []uint32 {
	n := r.GetNumPhonemes(sentenceId)
	if n <= 0 {
		return nil
	}
	p := C.PiperPhonemizeResultGetPhonemes(r.impl, C.int32_t(sentenceId))
	if p == nil {
		return nil
	}
	return unsafe.Slice((*uint32)(unsafe.Pointer(p)), n)
}

// GetVersionStr returns the piper-phonemize version string.
func GetVersionStr() string {
	return C.GoString(C.PiperPhonemizeGetVersionStr())
}

// Initialize initializes espeak-ng. This must be called before Phonemize.
// It is safe to call multiple times; only the first call takes effect.
//
// dataDir is the path to the espeak-ng-data directory.
// When using the piper-phonemize-go facade, pass "" to use the embedded default.
// Returns the sample rate (22050) on success, or -1 on failure.
func Initialize(dataDir string) int32 {
	cDataDir := C.CString(dataDir)
	defer C.free(unsafe.Pointer(cDataDir))
	return int32(C.PiperPhonemizeInitialize(cDataDir))
}

// Phonemize converts text to phonemes using espeak-ng.
//
// text is the UTF-8 text to phonemize.
// voice is the espeak-ng voice to use (e.g. "en-us"). Pass "" for default.
// Returns nil on failure or empty input.
func Phonemize(text, voice string) *PhonemizeResult {
	cText := C.CString(text)
	defer C.free(unsafe.Pointer(cText))

	cVoice := C.CString(voice)
	defer C.free(unsafe.Pointer(cVoice))

	impl := C.PiperPhonemizeText(cText, cVoice)
	if impl == nil {
		return nil
	}
	return &PhonemizeResult{impl: impl}
}

// DeletePhonemizeResult frees a PhonemizeResult.
func DeletePhonemizeResult(r *PhonemizeResult) {
	if r != nil && r.impl != nil {
		C.PiperPhonemizeDestroyResult(r.impl)
		r.impl = nil
	}
}
