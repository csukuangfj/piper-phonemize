// main.swift
//
// Example: Using piper-phonemize via Swift Package Manager
//
// Usage:
//   cd spm-examples
//   swift run piper-phonemize-example [espeak-ng-data-dir]

import Foundation
import piper_phonemize

func main() {
  let version = piperPhonemizeGetVersionStr()
  print("Version: \(version)")

  // Use command line argument or bundled data
  let dataDir: String
  if CommandLine.arguments.count > 1 {
    dataDir = CommandLine.arguments[1]
  } else if let bundledDir = piperPhonemizeBundledDataDir() {
    dataDir = bundledDir
  } else {
    print("Usage: \(CommandLine.arguments[0]) <espeak-ng-data-dir>")
    return
  }

  let sampleRate = piperPhonemizeInitialize(dataDir: dataDir)
  print("Sample rate: \(sampleRate)")

  let text = "Hello world. This is a test."
  print("\nInput: \"\(text)\"")

  if let result = piperPhonemizeText(text: text) {
    print("Sentences: \(result.numSentences)")
    for i in 0..<result.numSentences {
      let ipa = result.getPhonemesAsString(sentenceId: i)
      print("  Sentence \(i + 1): \(ipa)")
    }
  }
}

main()
