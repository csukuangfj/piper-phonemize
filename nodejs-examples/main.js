// main.js
//
// Example: Using piper-phonemize npm package in Node.js
//
// Usage:
//   cd nodejs-examples
//   npm install
//   node main.js

'use strict';

// When using the npm package, just require it directly
const piperPhonemize = require('piper-phonemize');

function main() {
  console.log('piper-phonemize version:', piperPhonemize.version);

  // No need to call initialize() - espeak-ng-data is bundled and auto-initialized!

  // Example texts to phonemize
  const examples = [
    { text: 'Hello world', voice: 'en-us' },
    { text: 'The quick brown fox jumps over the lazy dog.', voice: 'en-us' },
    { text: '你好世界。今天天气很好。', voice: 'en-us' },
    { text: 'Привет, мир!', voice: 'en-us' },
    { text: 'Hallo Welt', voice: 'de' },
    { text: 'Bonjour le monde', voice: 'fr' },
  ];

  for (const example of examples) {
    console.log(`\nInput: ${JSON.stringify(example.text)}`);
    console.log(`Voice: ${example.voice}`);

    // Phonemize to IPA strings
    const sentences = piperPhonemize.phonemizeToString(example.text, example.voice);

    if (!sentences) {
      console.log('  Result: (null - phonemization failed)');
    } else {
      console.log(`  Sentences: ${sentences.length}`);
      for (let i = 0; i < sentences.length; i++) {
        console.log(`    ${i + 1}: ${sentences[i]}`);
      }
    }
  }

  // Example: Get raw phoneme code points
  console.log('\n--- Raw phoneme code points example ---');
  const text = 'Hello';
  const voice = 'en-us';
  console.log(`Input: ${JSON.stringify(text)}`);

  const rawPhonemes = piperPhonemize.phonemize(text, voice);

  if (rawPhonemes) {
    for (let i = 0; i < rawPhonemes.length; i++) {
      console.log(`  Sentence ${i + 1}:`);
      console.log(`    Code points: [${rawPhonemes[i].map(cp => 'U+' + cp.toString(16).toUpperCase().padStart(4, '0')).join(', ')}]`);
      console.log(`    IPA: ${String.fromCodePoint(...rawPhonemes[i])}`);
    }
  }

  console.log('\nDone!');
}

main();
