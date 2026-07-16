# piper-phonemize

Phonemization library for [Piper](https://github.com/rhasspy/piper) text-to-speech, compiled to WebAssembly.

This package converts text to IPA phonemes using [espeak-ng](https://github.com/espeak-ng/espeak-ng), running entirely in Node.js without any native dependencies.

**espeak-ng-data is bundled** in this package — no need to download it separately!

## Installation

```bash
npm install piper-phonemize
```

## Quick Start

```javascript
const piperPhonemize = require('piper-phonemize');

// That's it! espeak-ng-data is bundled and auto-initialized on first use.
const result = piperPhonemize.phonemizeToString('Hello world', 'en-us');
console.log(result); // ['həlˈoʊ wˈɜːld']
```

## API Reference

### `initialize(dataDir?)`

Initialize espeak-ng with the given data directory. **Optional** — called automatically on first use with bundled data.

- `dataDir` (string, optional): Path to espeak-ng-data directory. If omitted, uses bundled data.
- Returns: Sample rate (22050) on success, -1 on failure

### `phonemize(text, voice)`

Phonemize text and return raw phoneme code points.

- `text` (string): Text to phonemize
- `voice` (string, optional): espeak-ng voice (e.g., 'en-us', 'de', 'fr'). Default: 'en-us'
- Returns: Array of sentences, each containing an array of uint32 code points, or null on failure

### `phonemizeToString(text, voice)`

Phonemize text and return IPA strings.

- `text` (string): Text to phonemize
- `voice` (string, optional): espeak-ng voice. Default: 'en-us'
- Returns: Array of IPA strings, or null on failure

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

## Example

```javascript
const piperPhonemize = require('piper-phonemize');

// No initialization needed — espeak-ng-data is bundled!

// Phonemize different languages
const examples = [
  { text: 'Hello world', voice: 'en-us' },
  { text: 'Hallo Welt', voice: 'de' },
  { text: 'Bonjour le monde', voice: 'fr' },
  { text: 'Hola mundo', voice: 'es' },
];

for (const { text, voice } of examples) {
  const result = piperPhonemize.phonemizeToString(text, voice);
  console.log(`${voice}: ${result[0]}`);
}

// Get raw code points
const phonemes = piperPhonemize.phonemize('Hello', 'en-us');
console.log('Code points:', phonemes[0]);
console.log('IPA:', String.fromCodePoint(...phonemes[0]));
```

## License

GPL-3.0-or-later (due to espeak-ng dependency)

## Links

- [GitHub Repository](https://github.com/csukuangfj/piper-phonemize)
- [Piper TTS](https://github.com/rhasspy/piper)
- [espeak-ng](https://github.com/espeak-ng/espeak-ng)
