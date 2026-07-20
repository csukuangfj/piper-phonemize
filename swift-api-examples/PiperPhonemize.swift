// PiperPhonemize.swift
//
// Swift wrapper for the piper-phonemize C API.
//
// Copyright (c) 2026  Xiaomi Corporation

import Foundation

/// Convert a Swift String to a C string pointer.
/// The returned pointer is valid for the lifetime of the NSString.
private func toCPointer(_ s: String) -> UnsafePointer<Int8>! {
  let cs = (s as NSString).utf8String
  return UnsafePointer<Int8>(cs)
}

/// Wrapper for PiperPhonemizeResult handle.
/// Automatically frees the result when deallocated.
public class PiperPhonemizeResult {
  private var handle: OpaquePointer?

  init(handle: OpaquePointer) {
    self.handle = handle
  }

  deinit {
    if handle != nil {
      PiperPhonemizeDestroyResult(handle)
      handle = nil
    }
  }

  /// Number of sentences in the result.
  public var numSentences: Int {
    return Int(PiperPhonemizeResultGetNumSentences(handle))
  }

  /// Get the number of phonemes in a given sentence.
  /// Returns -1 if sentenceId is out of range.
  public func getNumPhonemes(sentenceId: Int) -> Int {
    return Int(PiperPhonemizeResultGetNumPhonemes(handle, Int32(sentenceId)))
  }

  /// Get phonemes for a given sentence as an array of Unicode code points.
  public func getPhonemes(sentenceId: Int) -> [UInt32] {
    let n = getNumPhonemes(sentenceId: sentenceId)
    if n <= 0 {
      return []
    }

    let ptr = PiperPhonemizeResultGetPhonemes(handle, Int32(sentenceId))
    if ptr == nil {
      return []
    }

    var result = [UInt32]()
    result.reserveCapacity(n)
    for i in 0..<n {
      result.append(ptr![i])
    }
    return result
  }

  /// Get phonemes for a given sentence as an IPA string.
  public func getPhonemesAsString(sentenceId: Int) -> String {
    let phonemes = getPhonemes(sentenceId: sentenceId)
    return String(phonemes.compactMap { UnicodeScalar($0) }.map { Character($0) })
  }
}

/// Initialize espeak-ng with the given data directory.
/// Must be called before piperPhonemizeText().
/// Safe to call multiple times; only the first call takes effect.
///
/// - Parameter dataDir: Path to the espeak-ng-data directory.
/// - Returns: Sample rate (22050) on first call, 0 on subsequent calls, or -1 on failure.
public func piperPhonemizeInitialize(dataDir: String) -> Int {
  return Int(PiperPhonemizeInitialize(toCPointer(dataDir)))
}

/// Phonemize text using espeak-ng.
///
/// - Parameters:
///   - text: The text to phonemize (UTF-8).
///   - voice: The espeak-ng voice to use (e.g., "en-us"). Defaults to "en-us".
/// - Returns: A PiperPhonemizeResult object, or nil on failure.
public func piperPhonemizeText(text: String, voice: String = "en-us") -> PiperPhonemizeResult? {
  let handle = PiperPhonemizeText(toCPointer(text), toCPointer(voice))
  if handle == nil {
    return nil
  }
  return PiperPhonemizeResult(handle: handle!)
}

/// Return the piper-phonemize version string.
public func piperPhonemizeGetVersionStr() -> String {
  return String(cString: PiperPhonemizeGetVersionStr())
}
