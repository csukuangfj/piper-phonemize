// Copyright (c) 2026 Xiaomi Corporation
//
// Dart CLI hello_world example for piper-phonemize.
// Mirrors the Swift example in swift-api-examples/example.swift.
//
// Usage:
//   dart run bin/main.dart /path/to/espeak-ng-data

import 'dart:io';

import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void testPhonemize(String text, String voice) {
  print('\nInput: "$text"');
  print('Voice: $voice');

  final sentences = piper.PiperPhonemize.phonemize(text, voice: voice);
  print('Sentences: ${sentences.length}');

  if (sentences.isEmpty) {
    print('  (empty result)');
  }

  for (var i = 0; i < sentences.length; i++) {
    final phonemes = sentences[i];
    // Convert code points back to a string for display
    final ipa = String.fromCharCodes(phonemes);
    print('  Sentence ${i + 1}: $ipa');
  }
}

void main(List<String> args) {
  // Initialize FFI bindings
  piper.initBindings();

  // Get version
  final version = piper.PiperPhonemize.getVersion();
  print('Version: $version');

  if (args.isEmpty) {
    print('Usage: dart run bin/main.dart <espeak-ng-data-dir>');
    exit(1);
  }

  final dataDir = args[0];
  print('Data dir: $dataDir');

  final sampleRate = piper.PiperPhonemize.initialize(dataDir);
  print('Sample rate: $sampleRate');

  if (sampleRate < 0) {
    print('Error: Failed to initialize espeak-ng');
    exit(1);
  }

  // Test 1: English basic
  print('\n--- test_english_basic ---');
  testPhonemize('hello', 'en-us');

  // Multiple sentences
  testPhonemize(
    'The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump.',
    'en-us',
  );

  // British English
  testPhonemize(
    'The colour of the harbour is beautiful. He organised the theatre programme.',
    'en',
  );

  // Test 2: Punctuation
  print('\n--- test_punctuation ---');
  testPhonemize('this, is: a; test.', 'en-us');
  testPhonemize(
    "Hello! How are you? I'm fine, thanks. The price is \$3.50; not bad, right? Yes: it's a great deal!",
    'en-us',
  );

  // Test 3: Sentence splitting
  print('\n--- test_sentence_splitting ---');
  testPhonemize('Test one. Test two. Test three.', 'en-us');

  // Test 4: German
  print('\n--- test_german ---');
  testPhonemize('licht!', 'de');
  testPhonemize(
    'Guten Morgen, wie geht es Ihnen? Danke, mir geht es sehr gut. Das Wetter ist heute schön!',
    'de',
  );

  // Test 5: French
  print('\n--- test_french ---');
  testPhonemize(
    'Bonjour, comment allez-vous? Je vais très bien, merci! Le français est une belle langue.',
    'fr',
  );

  // Test 6: Spanish
  print('\n--- test_spanish ---');
  testPhonemize(
    'Buenos días, ¿cómo estás? Muy bien, gracias! El español es un idioma muy bonito.',
    'es',
  );

  // Test 7: Chinese
  print('\n--- test_chinese ---');
  testPhonemize('你好世界。今天天气很好。我很高兴认识你。', 'cmn');

  // Test 8: Russian
  print('\n--- test_russian ---');
  testPhonemize(
    'Привет, мир! Как у тебя дела? Сегодня хорошая погода.',
    'ru',
  );

  // Test 9: Numbers
  print('\n--- test_numbers ---');
  testPhonemize(
    'I have 42 apples and 3.14 pies. The year is 2025. Call me at 555-1234. The price is \$9.99!',
    'en-us',
  );

  // Test 10: Empty string
  print('\n--- test_empty ---');
  testPhonemize('', 'en-us');

  print('\nDone!');
}
