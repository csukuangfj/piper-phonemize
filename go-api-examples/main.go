package main

import (
	"fmt"
	"os"

	pp "piper_phonemize"
)

func main() {
	fmt.Println("Version:", pp.GetVersionStr())

	dataDir := "./espeak-ng-data"
	if len(os.Args) > 1 {
		dataDir = os.Args[1]
	}

	ret := pp.Initialize(dataDir)
	fmt.Println("Initialize:", ret)

	texts := []string{
		"hello world",
		"The quick brown fox jumps over the lazy dog.",
		"你好世界。今天天气很好。",
		"Привет, мир!",
	}

	for _, text := range texts {
		fmt.Printf("\nInput: %q\n", text)
		result := pp.Phonemize(text, "en-us")
		if result == nil {
			fmt.Println("  Phonemize returned nil")
			continue
		}

		fmt.Printf("  Sentences: %d\n", result.GetNumSentences())
		for i := 0; i < result.GetNumSentences(); i++ {
			phonemes := result.GetPhonemes(i)
			fmt.Printf("    sentence %d: %d phonemes %v\n", i, len(phonemes), phonemes)
		}
		pp.DeletePhonemizeResult(result)
	}
}
