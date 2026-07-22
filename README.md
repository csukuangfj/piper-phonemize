# piper-phonemize

## Try it Online

You can try piper-phonemize directly in your browser using WebAssembly:

- **Hugging Face Spaces**: https://huggingface.co/spaces/csukuangfj/piper-phonemize
- **ModelScope Studios** (for users in China, 中文用户): https://modelscope.cn/studios/csukuangfj/piper-phonemize/summary

## Introduction

Phonemization library for [Piper](https://github.com/rhasspy/piper) text-to-speech system.

Converts text to IPA phonemes using [espeak-ng](https://github.com/espeak-ng/espeak-ng).

Supports **Python**, **Go**, **Rust**, **Swift**, **Pascal**, **JavaScript (Node.js/WASM)**, **C/C++**, **Tauri**, **Android**, and **iOS**.

## Installation

### Python

```bash
pip install piper_phonemize -f https://k2-fsa.github.io/icefall/piper_phonemize.html
```

### Go

```bash
go get github.com/csukuangfj/piper-phonemize-go/piper_phonemize
```

### Rust

Add to your `Cargo.toml`:

```toml
[dependencies]
piper-phonemize = "0.3.6"
```

The crate automatically downloads prebuilt libraries and embeds espeak-ng-data.
No manual setup required.

### Swift

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/csukuangfj/piper-phonemize", branch: "master")
]
```

### JavaScript / Node.js

**WASM version** (works everywhere, no native dependencies):
```bash
npm install piper-phonemize
```

**Native addon** (better performance, requires platform-specific binary, which is installed automagically):
```bash
npm install piper-phonemize-node
```

### C / C++

Download pre-built libraries from [GitHub Releases](https://github.com/csukuangfj/piper-phonemize/releases) or build from source.

## Quick Start

### Python

```python
import piper_phonemize

# Initialize espeak-ng
piper_phonemize.initialize("/path/to/espeak-ng-data")

# Phonemize text
result = piper_phonemize.phonemize("Hello world", "en-us")
print(result)
```

### Go

```go
package main

import (
    "fmt"
    pp "github.com/csukuangfj/piper-phonemize-go/piper_phonemize"
)

func main() {
    pp.Initialize("") // uses embedded espeak-ng-data
    result := pp.Phonemize("Hello world", "en-us")
    defer pp.DeletePhonemizeResult(result)
    for i := 0; i < result.GetNumSentences(); i++ {
        phonemes := result.GetPhonemes(i)
        fmt.Printf("Sentence %d: %v\n", i, phonemes)
    }
}
```

### Rust

```rust
use piper_phonemize::phonemize_to_string;

fn main() {
    // No initialization needed - espeak-ng-data is embedded
    let sentences = phonemize_to_string("Hello world", "en-us").unwrap();
    for s in &sentences {
        println!("{}", s);
    }
}
```

### JavaScript / Node.js

**WASM version:**
```javascript
const piperPhonemize = require('piper-phonemize');

// espeak-ng-data is bundled — no initialization needed!
const result = piperPhonemize.phonemizeToString('Hello world', 'en-us');
console.log(result); // ['həlˈoʊ wˈɜːld']
```

**Native addon:**
```javascript
const piperPhonemize = require('piper-phonemize-node');

// espeak-ng-data is bundled — no initialization needed!
const result = piperPhonemize.phonemizeToString('Hello world', 'en-us');
console.log(result); // ['həlˈoʊ wˈɜːld']
```

### C

```c
#include "c-api.h"

int main() {
    PiperPhonemizeInitialize("/path/to/espeak-ng-data");

    PiperPhonemizeResult *result = PiperPhonemizeText("Hello world", "en-us");
    if (result) {
        int32_t num_sentences = PiperPhonemizeResultGetNumSentences(result);
        // Process phonemes...
        PiperPhonemizeDestroyResult(result);
    }
    return 0;
}
```

## Tauri Example (Cross-Platform GUI)

A cross-platform desktop/mobile app built with [Tauri v2](https://tauri.app).
See [tauri-examples/](tauri-examples/) for details.

Pre-built apps are available on the [GitHub Releases](https://github.com/csukuangfj/piper-phonemize/releases/tag/v1.4.7) page:

| Platform | File |
|---|---|
| macOS (Apple Silicon) | [piper-phonemize-tauri-macos-arm64.app.zip](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-macos-arm64.app.zip) |
| macOS (Intel) | [piper-phonemize-tauri-macos-x64.app.zip](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-macos-x64.app.zip) |
| Linux (x64) | [piper-phonemize-tauri-linux-x64.tar.bz2](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-linux-x64.tar.bz2) |
| Linux (arm64) | [piper-phonemize-tauri-linux-arm64.tar.bz2](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-linux-arm64.tar.bz2) |
| Windows (x64) | [piper-phonemize-tauri-windows-x64.zip](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/piper-phonemize-tauri-windows-x64.zip) |
| Android (APK) | [app-universal-release-unsigned.apk](https://github.com/csukuangfj/piper-phonemize/releases/download/v1.4.7/app-universal-release-unsigned.apk) |

## Building from Source

### Using CMake

```bash
cmake -Bbuild -DBUILD_SHARED_LIBS=ON
cmake --build build --config Release
```

### Using Docker

```bash
docker buildx build . -t piper-phonemize --output 'type=local,dest=dist'
```

## License

GPL-3.0-or-later (due to espeak-ng dependency)

## Links

- [Piper TTS](https://github.com/rhasspy/piper)
- [espeak-ng](https://github.com/espeak-ng/espeak-ng)
- [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)
- [GitHub Issues](https://github.com/csukuangfj/piper-phonemize/issues)
