// piper-phonemize.js
//
// High-level Browser API for piper-phonemize WASM module
//
// Copyright (c) 2026  Xiaomi Corporation

'use strict';

/**
 * Initialize espeak-ng with the preloaded data directory.
 * The espeak-ng-data is preloaded at /usr/share/espeak-ng-data by Emscripten.
 *
 * @returns {number} Sample rate (22050) on success, -1 on failure
 */
function piperPhonemizeInitialize() {
  const dataDir = '/usr/share/espeak-ng-data';
  const dataDirLen = Module.lengthBytesUTF8(dataDir) + 1;
  const dataDirPtr = Module._malloc(dataDirLen);
  Module.stringToUTF8(dataDir, dataDirPtr, dataDirLen);
  try {
    return Module._PiperPhonemizeInitialize(dataDirPtr);
  } finally {
    Module._free(dataDirPtr);
  }
}

/**
 * Get the version string
 * @returns {string} Version string
 */
function piperPhonemizeGetVersionStr() {
  const ptr = Module._PiperPhonemizeGetVersionStr();
  return Module.UTF8ToString(ptr);
}

/**
 * Phonemize text using espeak-ng
 *
 * @param {string} text - Text to phonemize
 * @param {string} [voice='en-us'] - espeak-ng voice (e.g., 'en-us', 'de', 'fr')
 * @returns {Array<Array<number>>|null} Array of sentences, each containing phoneme code points (uint32), or null on failure
 */
function piperPhonemize(text, voice) {
  if (!voice) {
    voice = 'en-us';
  }

  const textLen = Module.lengthBytesUTF8(text) + 1;
  const voiceLen = Module.lengthBytesUTF8(voice) + 1;
  const textPtr = Module._malloc(textLen);
  const voicePtr = Module._malloc(voiceLen);
  Module.stringToUTF8(text, textPtr, textLen);
  Module.stringToUTF8(voice, voicePtr, voiceLen);

  try {
    const resultPtr = Module._PiperPhonemizeText(textPtr, voicePtr);

    if (resultPtr === 0) {
      return null;
    }

    try {
      const numSentences = Module._PiperPhonemizeResultGetNumSentences(resultPtr);
      const sentences = [];

      for (let i = 0; i < numSentences; i++) {
        const numPhonemes = Module._PiperPhonemizeResultGetNumPhonemes(resultPtr, i);

        if (numPhonemes <= 0) {
          sentences.push([]);
          continue;
        }

        const phonemesPtr = Module._PiperPhonemizeResultGetPhonemes(resultPtr, i);

        if (phonemesPtr === 0) {
          sentences.push([]);
          continue;
        }

        // Read uint32 array from WASM heap
        const phonemes = [];
        for (let j = 0; j < numPhonemes; j++) {
          phonemes.push(Module.HEAPU32[(phonemesPtr >> 2) + j]);
        }
        sentences.push(phonemes);
      }

      return sentences;
    } finally {
      Module._PiperPhonemizeDestroyResult(resultPtr);
    }
  } finally {
    Module._free(textPtr);
    Module._free(voicePtr);
  }
}

/**
 * Phonemize text and return as IPA string
 *
 * @param {string} text - Text to phonemize
 * @param {string} [voice='en-us'] - espeak-ng voice
 * @returns {Array<string>|null} Array of sentence strings, or null on failure
 */
function piperPhonemizeToString(text, voice) {
  const sentences = piperPhonemize(text, voice);

  if (!sentences) {
    return null;
  }

  return sentences.map(phonemes =>
    String.fromCodePoint(...phonemes)
  );
}
