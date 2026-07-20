// example.swift
//
// Example: Phonemize text using piper-phonemize Swift API
//
// Usage:
//   ./example /path/to/espeak-ng-data

import Foundation

@main
struct App {
  static func main() {
    let version = piperPhonemizeGetVersionStr()
    print("Version: \(version)")

    guard CommandLine.arguments.count > 1 else {
      print("Usage: \(CommandLine.arguments[0]) <espeak-ng-data-dir>")
      return
    }

    let dataDir = CommandLine.arguments[1]
    print("Data dir: \(dataDir)")

    let sampleRate = piperPhonemizeInitialize(dataDir: dataDir)
    print("Sample rate: \(sampleRate)")

    guard sampleRate >= 0 else {
      print("Error: Failed to initialize espeak-ng")
      return
    }

    // Test 1: English basic
    print("\n--- test_english_basic ---")
    testPhonemize(text: "hello", voice: "en-us")

    // Multiple sentences
    testPhonemize(
      text: "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump.",
      voice: "en-us"
    )

    // British English
    testPhonemize(
      text: "The colour of the harbour is beautiful. He organised the theatre programme.",
      voice: "en"
    )

    // Test 2: Punctuation
    print("\n--- test_punctuation ---")
    testPhonemize(text: "this, is: a; test.", voice: "en-us")
    testPhonemize(
      text: "Hello! How are you? I'm fine, thanks. The price is $3.50; not bad, right? Yes: it's a great deal!",
      voice: "en-us"
    )

    // Test 3: Sentence splitting
    print("\n--- test_sentence_splitting ---")
    testPhonemize(text: "Test one. Test two. Test three.", voice: "en-us")

    // Test 4: German
    print("\n--- test_german ---")
    testPhonemize(text: "licht!", voice: "de")
    testPhonemize(
      text: "Guten Morgen, wie geht es Ihnen? Danke, mir geht es sehr gut. Das Wetter ist heute schön!",
      voice: "de"
    )

    // Test 5: French
    print("\n--- test_french ---")
    testPhonemize(
      text: "Bonjour, comment allez-vous? Je vais très bien, merci! Le français est une belle langue.",
      voice: "fr"
    )

    // Test 6: Spanish
    print("\n--- test_spanish ---")
    testPhonemize(
      text: "Buenos días, ¿cómo estás? Muy bien, gracias! El español es un idioma muy bonito.",
      voice: "es"
    )

    // Test 7: Chinese
    print("\n--- test_chinese ---")
    testPhonemize(text: "你好世界。今天天气很好。我很高兴认识你。", voice: "cmn")

    // Test 8: Russian
    print("\n--- test_russian ---")
    testPhonemize(
      text: "Привет, мир! Как у тебя дела? Сегодня хорошая погода.",
      voice: "ru"
    )

    // Test 9: Numbers
    print("\n--- test_numbers ---")
    testPhonemize(
      text: "I have 42 apples and 3.14 pies. The year is 2025. Call me at 555-1234. The price is $9.99!",
      voice: "en-us"
    )

    // Test 10: Empty string
    print("\n--- test_empty ---")
    testPhonemize(text: "", voice: "en-us")

    print("\nDone!")
  }

  static func testPhonemize(text: String, voice: String) {
    print("\nInput: \"\(text)\"")
    print("Voice: \(voice)")

    if let result = piperPhonemizeText(text: text, voice: voice) {
      let numSentences = result.numSentences
      print("Sentences: \(numSentences)")

      if numSentences == 0 {
        print("  (empty result)")
      }

      for i in 0..<numSentences {
        let ipa = result.getPhonemesAsString(sentenceId: i)
        print("  Sentence \(i + 1): \(ipa)")
      }
    } else {
      if text.isEmpty {
        print("  (nil result for empty text)")
      } else {
        print("  Error: phonemization failed")
      }
    }
  }
}
