// piper-phonemize - Phonemization library for Piper text-to-speech
//
// Copyright (c) 2026  Xiaomi Corporation
'use strict'

const path = require('path');

// Emscripten >= 3.1.50 made MODULARIZE always return a Promise, even with
// WASM_ASYNC_COMPILATION=0. The runtime still attaches the exports onto the
// user-supplied moduleArg synchronously, so we pass our own object and ignore
// the (already-resolved) Promise — keeping this whole module synchronous.
const wasmModule = {
  print: console.log,
  printErr: console.error,
};
require('./piper-phonemize-wasm-nodejs.js')(wasmModule);
const piper_phonemize = require('./piper-phonemize.node.js');

// Initialize the WASM module synchronously
piper_phonemize.initSync(wasmModule);

let isInitialized = false;

// Path to bundled espeak-ng-data
// espeak-ng expects the parent directory and appends '/espeak-ng-data' itself
const bundledDataDir = __dirname;

/**
 * Initialize espeak-ng with the given data directory.
 * If not called, phonemize() will auto-initialize with bundled data.
 *
 * @param {string} [dataDir] - Path to espeak-ng-data directory. If omitted, uses bundled data.
 * @returns {number} Sample rate (22050) on success, -1 on failure
 */
function initialize(dataDir) {
  if (!dataDir) {
    dataDir = bundledDataDir;
  }
  const ret = piper_phonemize.initialize(dataDir);
  if (ret > 0) {
    isInitialized = true;
  }
  return ret;
}

/**
 * Ensure espeak-ng is initialized. Uses bundled data if not already initialized.
 */
function ensureInitialized() {
  if (!isInitialized) {
    const ret = initialize(bundledDataDir);
    if (ret < 0) {
      throw new Error('Failed to initialize espeak-ng. Make sure espeak-ng-data is available.');
    }
  }
}

/**
 * Get the version string
 * @returns {string} Version string
 */
function getVersion() {
  return piper_phonemize.getVersionStr();
}

/**
 * Phonemize text using espeak-ng
 *
 * @param {string} text - Text to phonemize
 * @param {string} [voice='en-us'] - espeak-ng voice (e.g., 'en-us', 'de', 'fr')
 * @returns {Array<Array<number>>|null} Array of sentences, each containing phoneme code points (uint32), or null on failure
 */
function phonemize(text, voice) {
  ensureInitialized();
  return piper_phonemize.phonemize(text, voice);
}

/**
 * Phonemize text and return as IPA string
 *
 * @param {string} text - Text to phonemize
 * @param {string} [voice='en-us'] - espeak-ng voice
 * @returns {Array<string>|null} Array of IPA strings, or null on failure
 */
function phonemizeToString(text, voice) {
  ensureInitialized();
  return piper_phonemize.phonemizeToString(text, voice);
}

module.exports = {
  initialize,
  phonemize,
  phonemizeToString,
  version: getVersion(),
};
