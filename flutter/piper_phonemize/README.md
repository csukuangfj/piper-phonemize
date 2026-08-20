# piper_phonemize

Dart and Flutter bindings for [piper-phonemize](https://github.com/csukuangfj/piper-phonemize), a fast phonemization library backed by espeak-ng.

Converts text to phoneme code points for use with text-to-speech systems.

## Features

- Phonemize text using espeak-ng (supports many languages)
- Returns Unicode code points per sentence
- Works on all platforms: macOS, iOS, Linux, Windows, Android
- Single package — no platform-specific sub-packages needed

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  piper_phonemize: ^1.4.8
```

## Usage

### Flutter

```dart
import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the FFI bindings (auto-resolves native library)
  await piper.initBindingsAsync();

  // Extract espeak-ng-data to filesystem (first run only)
  final dataDir = await piper.PiperPhonemize.extractEspeakNgData();

  // Initialize espeak-ng
  await piper.PiperPhonemize.initialize(dataDir);

  // Phonemize text
  final phonemes = piper.PiperPhonemize.phonemize('Hello world');
  print(phonemes);  // List<List<int>> — code points per sentence
}
```

### Dart CLI

```dart
import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void main() {
  // Initialize FFI bindings (resolves path via Isolate.resolvePackageUriSync)
  piper.initBindings();

  // Initialize espeak-ng with data directory
  piper.PiperPhonemize.initialize('/path/to/espeak-ng-data');

  // Phonemize text
  final phonemes = piper.PiperPhonemize.phonemize('Hello world');
  print(phonemes);
}
```

## Platform Setup

Native libraries are bundled with the package. No manual installation needed.

## License

GNU General Public License v3.0 — see [LICENSE.md](https://github.com/csukuangfj/piper-phonemize/blob/master/LICENSE.md).
