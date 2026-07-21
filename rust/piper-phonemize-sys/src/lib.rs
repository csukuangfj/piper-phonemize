//! Raw FFI bindings to the piper-phonemize C API.

use std::os::raw::{c_char, c_int, c_uint};

/// Opaque handle for phonemize results.
#[repr(C)]
pub struct PiperPhonemizeResult {
    _private: [u8; 0],
}

extern "C" {
    /// Return the piper-phonemize version string.
    pub fn PiperPhonemizeGetVersionStr() -> *const c_char;

    /// Initialize espeak-ng with the given data directory.
    /// Returns sample rate (22050) on success, -1 on failure.
    pub fn PiperPhonemizeInitialize(data_dir: *const c_char) -> c_int;

    /// Phonemize text using espeak-ng.
    /// Returns an opaque result handle, or null on failure.
    pub fn PiperPhonemizeText(
        text: *const c_char,
        voice: *const c_char,
    ) -> *const PiperPhonemizeResult;

    /// Get the number of sentences in the result.
    pub fn PiperPhonemizeResultGetNumSentences(
        result: *const PiperPhonemizeResult,
    ) -> c_int;

    /// Get the number of phonemes in a given sentence.
    pub fn PiperPhonemizeResultGetNumPhonemes(
        result: *const PiperPhonemizeResult,
        sentence_id: c_int,
    ) -> c_int;

    /// Get pointer to phoneme array (uint32 Unicode code points) for a sentence.
    pub fn PiperPhonemizeResultGetPhonemes(
        result: *const PiperPhonemizeResult,
        sentence_id: c_int,
    ) -> *const c_uint;

    /// Free a result handle.
    pub fn PiperPhonemizeDestroyResult(result: *mut PiperPhonemizeResult);
}
