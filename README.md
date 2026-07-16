# piper-phonemize

Phonemization library for [Piper](https://github.com/rhasspy/piper) text-to-speech system.

Converts text to IPA phonemes using [espeak-ng](https://github.com/espeak-ng/espeak-ng).

Supports **Python**, **Go**, **JavaScript (Node.js/WASM)**, and **C/C++**.

## Installation

### Python

```bash
pip install piper_phonemize -f https://k2-fsa.github.io/icefall/piper_phonemize.html
```

### Go

```bash
go get github.com/csukuangfj/piper-phonemize-go/piper_phonemize
```

### JavaScript / Node.js

```bash
npm install piper-phonemize
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

### JavaScript / Node.js

```javascript
const piperPhonemize = require('piper-phonemize');

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
