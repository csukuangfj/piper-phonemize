//! # piper-phonemize
//!
//! Phonemization library for [Piper](https://github.com/rhasspy/piper) text-to-speech.
//!
//! Converts text to IPA phonemes using [espeak-ng](https://github.com/espeak-ng/espeak-ng).
//!
//! ## Quick Start
//!
//! ```no_run
//! use piper_phonemize::{initialize, phonemize_to_string};
//!
//! initialize("/path/to/espeak-ng-data").unwrap();
//! let sentences = phonemize_to_string("Hello world", "en-us").unwrap();
//! for s in &sentences {
//!     println!("{}", s);
//! }
//! ```

use std::ffi::{CStr, CString};

use piper_phonemize_sys as sys;

/// A handle to the phonemize result.
///
/// Automatically frees the underlying C result when dropped.
pub struct PiperPhonemizeResult {
    ptr: *const sys::PiperPhonemizeResult,
}

unsafe impl Send for PiperPhonemizeResult {}
unsafe impl Sync for PiperPhonemizeResult {}

impl PiperPhonemizeResult {
    /// Returns the number of sentences in the result.
    pub fn num_sentences(&self) -> usize {
        unsafe { sys::PiperPhonemizeResultGetNumSentences(self.ptr) as usize }
    }

    /// Returns the number of phonemes in a given sentence (0-based index).
    /// Returns None if sentence_id is out of range.
    pub fn num_phonemes(&self, sentence_id: usize) -> Option<usize> {
        let n = unsafe {
            sys::PiperPhonemizeResultGetNumPhonemes(self.ptr, sentence_id as i32)
        };
        if n < 0 {
            None
        } else {
            Some(n as usize)
        }
    }

    /// Returns phonemes for a given sentence as Unicode code points.
    /// Returns None if sentence_id is out of range.
    pub fn get_phonemes(&self, sentence_id: usize) -> Option<Vec<u32>> {
        let n = self.num_phonemes(sentence_id)?;
        if n == 0 {
            return Some(Vec::new());
        }
        let ptr = unsafe {
            sys::PiperPhonemizeResultGetPhonemes(self.ptr, sentence_id as i32)
        };
        if ptr.is_null() {
            return None;
        }
        let phonemes = unsafe { std::slice::from_raw_parts(ptr, n) };
        Some(phonemes.to_vec())
    }

    /// Returns phonemes for a given sentence as an IPA string.
    /// Returns None if sentence_id is out of range.
    pub fn get_phonemes_as_string(&self, sentence_id: usize) -> Option<String> {
        let phonemes = self.get_phonemes(sentence_id)?;
        let s: String = phonemes
            .iter()
            .filter_map(|&cp| char::from_u32(cp))
            .collect();
        Some(s)
    }
}

impl Drop for PiperPhonemizeResult {
    fn drop(&mut self) {
        if !self.ptr.is_null() {
            unsafe {
                sys::PiperPhonemizeDestroyResult(self.ptr as *mut _);
            }
        }
    }
}

/// Initialize espeak-ng with the given data directory.
///
/// Must be called before `phonemize()`. Safe to call multiple times;
/// only the first call takes effect.
///
/// Returns the sample rate (22050) on success.
pub fn initialize(data_dir: &str) -> Result<i32, &'static str> {
    let c_dir = CString::new(data_dir).map_err(|_| "data_dir contains null byte")?;
    let ret = unsafe { sys::PiperPhonemizeInitialize(c_dir.as_ptr()) };
    if ret < 0 {
        Err("Failed to initialize espeak-ng")
    } else {
        Ok(ret)
    }
}

/// Phonemize text using espeak-ng.
///
/// Returns `None` on failure.
pub fn phonemize(text: &str, voice: &str) -> Option<PiperPhonemizeResult> {
    let c_text = CString::new(text).ok()?;
    let c_voice = CString::new(voice).ok()?;
    let ptr = unsafe {
        sys::PiperPhonemizeText(c_text.as_ptr(), c_voice.as_ptr())
    };
    if ptr.is_null() {
        None
    } else {
        Some(PiperPhonemizeResult { ptr })
    }
}

/// Phonemize text and return as IPA strings.
///
/// Returns `None` on failure.
pub fn phonemize_to_string(text: &str, voice: &str) -> Option<Vec<String>> {
    let result = phonemize(text, voice)?;
    let mut sentences = Vec::new();
    for i in 0..result.num_sentences() {
        if let Some(s) = result.get_phonemes_as_string(i) {
            sentences.push(s);
        }
    }
    Some(sentences)
}

/// Return the piper-phonemize version string.
pub fn get_version() -> String {
    unsafe {
        let ptr = sys::PiperPhonemizeGetVersionStr();
        CStr::from_ptr(ptr).to_string_lossy().into_owned()
    }
}
