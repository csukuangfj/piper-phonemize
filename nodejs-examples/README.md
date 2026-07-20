# Node.js Examples for piper-phonemize

This directory contains examples for using piper-phonemize in Node.js.

## Prerequisites

- Node.js 14 or later

## Install dependencies

```bash
cd nodejs-examples
npm install
```

## Run the examples

Quick test:

```
node -e "const p = require('piper-phonemize'); console.log(p.phonemize('Hello! How are you doing?', 'en-us'))"
```

### Simple example

```bash
node simple.js
```

### Full example

```bash
node main.js
```

## Expected output

```
Input: "Hello world"
Voice: en-us
  Sentences: 1
    1: həlˈoʊ wˈɜːld

Input: "The quick brown fox jumps over the lazy dog."
Voice: en-us
  Sentences: 1
    1: ðə kwˈɪk bɹˈaʊn fˈɑːks dʒˈʌmps ˌoʊvɚ ðə lˈeɪzi dˈɑːɡ.

...
```

## Using the API in your project

```bash
npm install piper-phonemize
```

```javascript
const piperPhonemize = require('piper-phonemize');

// That's it! espeak-ng-data is bundled and auto-initialized.
const result = piperPhonemize.phonemizeToString('Hello world', 'en-us');
console.log(result); // ['həlˈoʊ wˈɜːld']
```

## API Reference

### `phonemize(text, voice?)`

Phonemize text and return raw phoneme code points.

- `text` (string): Text to phonemize
- `voice` (string, optional): espeak-ng voice (e.g., 'en-us', 'de', 'fr'). Default: 'en-us'
- Returns: Array of sentences, each containing an array of uint32 code points, or null on failure

### `phonemizeToString(text, voice?)`

Phonemize text and return IPA strings.

- `text` (string): Text to phonemize
- `voice` (string, optional): espeak-ng voice. Default: 'en-us'
- Returns: Array of IPA strings, or null on failure

### `initialize(dataDir?)`

Initialize espeak-ng with a custom data directory. **Optional** — called automatically on first use with bundled data.

- `dataDir` (string, optional): Path to espeak-ng-data directory. If omitted, uses bundled data.
- Returns: Sample rate (22050) on success, -1 on failure

### `version`

The version of piper-phonemize (string).

## Supported Languages

espeak-ng supports many languages including:

- English (en-us, en)
- German (de)
- French (fr)
- Spanish (es)
- Italian (it)
- Portuguese (pt)
- Russian (ru)
- Chinese (zh)
- Japanese (ja)
- Korean (ko)
- And many more...

## Links

- [npm package](https://www.npmjs.com/package/piper-phonemize)
- [GitHub Repository](https://github.com/csukuangfj/piper-phonemize)
