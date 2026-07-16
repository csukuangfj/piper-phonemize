// app-phonemize.js
//
// Demo application for piper-phonemize WASM
//
// Copyright (c) 2026  Xiaomi Corporation

'use strict';

const textArea = document.getElementById('text');
const voiceSelect = document.getElementById('voice');
const phonemizeBtn = document.getElementById('phonemizeBtn');
const resultsArea = document.getElementById('results');
const statusElement = document.getElementById('status');

let isInitialized = false;

// https://emscripten.org/docs/api_reference/module.html#Module.locateFile
var Module = {
  locateFile: function(path, scriptDirectory = '') {
    console.log(`path: ${path}, scriptDirectory: ${scriptDirectory}`);
    return scriptDirectory + path;
  },

  setStatus: function(status) {
    console.log(`status: ${status}`);
    statusElement.textContent = status;
  },

  onRuntimeInitialized: function() {
    console.log('WASM runtime initialized');

    try {
      const ret = piperPhonemizeInitialize();
      console.log('Initialize returned:', ret);

      if (ret > 0) {
        isInitialized = true;
        const version = piperPhonemizeGetVersionStr();
        statusElement.textContent = `Ready (version: ${version}, sample rate: ${ret})`;
        phonemizeBtn.disabled = false;
      } else {
        statusElement.textContent = 'Error: Failed to initialize espeak-ng';
      }
    } catch (e) {
      console.error('Initialization error:', e);
      statusElement.textContent = 'Error: ' + e.message;
    }
  }
};

// Handle phonemize button click
phonemizeBtn.onclick = function() {
  if (!isInitialized) {
    resultsArea.value = 'Error: Not initialized yet';
    return;
  }

  const text = textArea.value.trim();
  if (!text) {
    resultsArea.value = 'Please enter some text';
    return;
  }

  const voice = voiceSelect.value;

  try {
    const startTime = performance.now();
    const sentences = piperPhonemizeToString(text, voice);
    const endTime = performance.now();
    const elapsed = ((endTime - startTime) / 1000).toFixed(3);

    if (!sentences) {
      resultsArea.value = 'Error: Phonemization failed';
      return;
    }

    let output = '';
    output += `Voice: ${voice}\n`;
    output += `Time: ${elapsed}s\n`;
    output += `Sentences: ${sentences.length}\n`;
    output += '\n';

    for (let i = 0; i < sentences.length; i++) {
      output += `Sentence ${i + 1}:\n`;
      output += `  IPA: ${sentences[i]}\n`;

      // Also show code points
      const codePoints = [];
      for (let j = 0; j < sentences[i].length; j++) {
        codePoints.push('U+' + sentences[i].codePointAt(j).toString(16).toUpperCase().padStart(4, '0'));
      }
      output += `  Code points: ${codePoints.join(' ')}\n`;
      output += '\n';
    }

    resultsArea.value = output;
  } catch (e) {
    console.error('Phonemization error:', e);
    resultsArea.value = 'Error: ' + e.message;
  }
};
