// piper-phonemize.js
//
// High-level Node.js API for piper-phonemize native addon
//
// Copyright (c) 2026  Xiaomi Corporation

'use strict';

const path = require('path');
const addon = require('./addon');

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
  const ret = addon.initialize(dataDir);
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
      throw new Error(
        'Failed to initialize espeak-ng. ' +
        'Make sure espeak-ng-data is available at: ' + bundledDataDir
      );
    }
  }
}

/**
 * Get the version string
 * @returns {string} Version string
 */
function getVersionStr() {
  return addon.getVersionStr();
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
  return addon.phonemize(text, voice || 'en-us');
}

/**
 * Phonemize text and return as IPA string
 *
 * @param {string} text - Text to phonemize
 * @param {string} [voice='en-us'] - espeak-ng voice
 * @returns {Array<string>|null} Array of IPA strings, or null on failure
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

module.exports = {
  initialize,
  phonemize,
  phonemizeToString,
  version: getVersionStr(),
};
