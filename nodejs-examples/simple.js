// simple.js
//
// Simple example: Using piper-phonemize npm package in Node.js
//
// This example shows the minimal code needed to use piper-phonemize.
//
// Usage:
//   cd nodejs-examples
//   npm install
//   node simple.js

'use strict';

// Just require the npm package - that's it!
const piperPhonemize = require('piper-phonemize');

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
