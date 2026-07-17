// simple.js
//
// Simple example: Using piper-phonemize native addon in Node.js
//
// Usage:
//   cd nodejs-addon-examples
//   npm install
//   node simple.js

'use strict';

// Just require the package - that's it!
const piperPhonemize = require('piper-phonemize-node');

// No initialization needed - espeak-ng-data is bundled!

const text = 'Hello world!';
const voice = 'en-us';

console.log(`Input: "${text}"`);
console.log(`Voice: ${voice}`);

const result = piperPhonemize.phonemizeToString(text, voice);

if (result) {
  console.log(`IPA: ${result[0]}`);
} else {
  console.log('Phonemization failed');
}
