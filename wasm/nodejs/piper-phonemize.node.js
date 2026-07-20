// piper-phonemize.node.js
//
// High-level Node.js API for piper-phonemize WASM module
//
// Copyright (c) 2026  Xiaomi Corporation

'use strict';

let Module = null;

/**
 * Initialize the WASM module asynchronously
 * @param {Object} moduleFactory - The Emscripten module factory function
 * @param {Object} [options] - Optional configuration
 * @param {Function} [options.print] - Function to handle stdout (default: console.log)
 * @param {Function} [options.printErr] - Function to handle stderr (default: console.error)
 * @returns {Promise<void>}
 */
async function init(moduleFactory) {
  Module = await moduleFactory();
}

/**
 * Initialize the WASM module synchronously with a pre-created module object.
 * Use this when the module is already initialized (e.g., via MODULARIZE with
 * a custom object).
 *
 * @param {Object} module - The pre-initialized Emscripten module object
 */
function initSync(module) {
  Module = module;
}

/**
 * Initialize espeak-ng with the given data directory.
 * Must be called before phonemize().
 *
 * @param {string} dataDir - Path to espeak-ng-data directory
 * @returns {number} Sample rate (22050) on success, -1 on failure
 */
function initialize(dataDir) {
  if (!Module) {
    throw new Error('Module not initialized. Call init() first.');
  }

  // Allocate buffer for the string (including null terminator)
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
function getVersionStr() {
  if (!Module) {
    throw new Error('Module not initialized. Call init() first.');
  }

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
function phonemize(text, voice) {
  if (!Module) {
    throw new Error('Module not initialized. Call init() first.');
  }

  if (!voice) {
    voice = 'en-us';
  }

  // Allocate buffers for strings
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
function phonemizeToString(text, voice) {
  const sentences = phonemize(text, voice);

  if (!sentences) {
    return null;
  }

  return sentences.map(phonemes =>
    String.fromCodePoint(...phonemes)
  );
}

// Export for CommonJS (Node.js)
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    init,
    initSync,
    initialize,
    getVersionStr,
    phonemize,
    phonemizeToString,
  };
}

// Export for ES modules
if (typeof exports !== 'undefined') {
  exports.init = init;
  exports.initSync = initSync;
  exports.initialize = initialize;
  exports.getVersionStr = getVersionStr;
  exports.phonemize = phonemize;
  exports.phonemizeToString = phonemizeToString;
}
