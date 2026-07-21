# Go API Examples for piper-phonemize

This directory contains Go examples for the piper-phonemize C API.

## Prerequisites

- Go 1.17 or later

## Run the example

```bash
cd go-api-examples
go mod tidy
go run main.go
```

You can also pass a custom espeak-ng-data path:

```bash
go run main.go /path/to/espeak-ng-data
```

## Expected output

```
Version: 1.4.7
Initialize: 22050

Input: "hello world"
  Sentences: 1
    sentence 0: həlˈoʊ wˈɜːld

Input: "The quick brown fox jumps over the lazy dog."
  Sentences: 1
    sentence 0: ðə kwˈɪk bɹˈaʊn fˈɑːks dʒˈʌmps ˌoʊvɚ ðə lˈeɪzi dˈɑːɡ.

...
```

## Using the Go package in your project

To use piper-phonemize in your own Go project:

```bash
go get github.com/csukuangfj/piper-phonemize-go/piper_phonemize
```

Then import it in your code:

```go
import pp "github.com/csukuangfj/piper-phonemize-go/piper_phonemize"

// Initialize espeak-ng (empty string uses embedded data)
pp.Initialize("")

// Phonemize text
result := pp.Phonemize("hello world", "en-us")
defer pp.DeletePhonemizeResult(result)

for i := 0; i < result.GetNumSentences(); i++ {
    phonemes := result.GetPhonemes(i)
    // phonemes is []uint32 of Unicode code points
}
```
