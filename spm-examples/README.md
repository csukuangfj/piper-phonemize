# Swift Package Manager Examples

This directory contains examples for using piper-phonemize via Swift Package Manager.

## Run the example

```bash
cd spm-examples
bash run.sh
```

Or manually:

```bash
cd spm-examples
swift run piper-phonemize-example /path/to/espeak-ng-data
```

## Usage

Add the dependency to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/csukuangfj/piper-phonemize.git", from: "1.4.7"),
]
```

Then add the target dependency:

```swift
.target(
  name: "YourTarget",
  dependencies: ["piper-phonemize"]
),
```

## Example

```swift
import piper_phonemize

// No initialization needed - espeak-ng-data is bundled!
let result = piperPhonemizeText(text: "Hello world", voice: "en-us")
if let result = result {
  for i in 0..<result.numSentences {
    let ipa = result.getPhonemesAsString(sentenceId: i)
    print(ipa)
  }
}
```

## API Reference

### `piperPhonemizeText(text:voice:)`

Phonemize text using espeak-ng. **Auto-initializes** with bundled data if not already initialized.

- `text`: The text to phonemize (UTF-8)
- `voice`: The espeak-ng voice to use (e.g., "en-us"). Defaults to "en-us"
- Returns: A `PiperPhonemizeResult` object, or nil on failure

### `piperPhonemizeInitialize(dataDir:)`

Initialize espeak-ng with a custom data directory. **Optional** — called automatically on first use with bundled data.

- `dataDir`: Path to the espeak-ng-data directory
- Returns: Sample rate (22050) on success, or -1 on failure

### `piperPhonemizeGetVersionStr()`

Return the piper-phonemize version string.

### `PiperPhonemizeResult`

- `numSentences`: Number of sentences in the result
- `getNumPhonemes(sentenceId:)`: Number of phonemes in a sentence
- `getPhonemes(sentenceId:)`: Array of Unicode code points
- `getPhonemesAsString(sentenceId:)`: IPA string
