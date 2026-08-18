// PiperPhonemize.swift
//
// Swift wrapper for the piper-phonemize C API.
//
// Copyright (c) 2026  Xiaomi Corporation

import Foundation
#if SWIFT_PACKAGE
import PiperPhonemizeC
#endif

/// Convert a Swift String to a C string pointer.
private func toCPointer(_ s: String) -> UnsafePointer<Int8>! {
  let cs = (s as NSString).utf8String
  return UnsafePointer<Int8>(cs)
}

/// Wrapper for PiperPhonemizeResult handle.
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

  public var numSentences: Int {
    return Int(PiperPhonemizeResultGetNumSentences(handle))
  }

  public func getNumPhonemes(sentenceId: Int) -> Int {
    return Int(PiperPhonemizeResultGetNumPhonemes(handle, Int32(sentenceId)))
  }

  public func getPhonemes(sentenceId: Int) -> [UInt32] {
    let n = getNumPhonemes(sentenceId: sentenceId)
    if n <= 0 { return [] }

    let ptr = PiperPhonemizeResultGetPhonemes(handle, Int32(sentenceId))
    if ptr == nil { return [] }

    var result = [UInt32]()
    result.reserveCapacity(n)
    for i in 0..<n {
      result.append(ptr![i])
    }
    return result
  }

  public func getPhonemesAsString(sentenceId: Int) -> String {
    let phonemes = getPhonemes(sentenceId: sentenceId)
    return String(phonemes.compactMap { UnicodeScalar($0) }.map { Character($0) })
  }
}

public func piperPhonemizeInitialize(dataDir: String) -> Int {
  return Int(PiperPhonemizeInitialize(toCPointer(dataDir)))
}

public func piperPhonemizeText(text: String, voice: String = "en-us") -> PiperPhonemizeResult? {
  let handle = PiperPhonemizeText(toCPointer(text), toCPointer(voice))
  if handle == nil { return nil }
  return PiperPhonemizeResult(handle: handle!)
}

public func piperPhonemizeGetVersionStr() -> String {
  return String(cString: PiperPhonemizeGetVersionStr()!)
}

/// Return the path to the bundled espeak-ng-data directory.
/// Only available when using SPM.
public func piperPhonemizeBundledDataDir() -> String? {
  #if SWIFT_PACKAGE
  return Bundle.module.url(forResource: "espeak-ng-data", withExtension: nil)?.path
  #else
  return nil
  #endif
}
