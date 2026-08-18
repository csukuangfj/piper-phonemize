// Copyright 2026 Xiaomi Corporation

import com.github.csukuangfj.piper.phonemize.PiperPhonemize;

public class PhonemizeText {
    public static void main(String[] args) {
        System.out.printf("piper-phonemize version: %s\n", PiperPhonemize.getVersionStr());

        // Initialize with embedded espeak-ng-data
        int sampleRate = PiperPhonemize.initialize();
        System.out.printf("Sample rate: %d\n", sampleRate);

        String text = "Hello world. This is a test. The weather is beautiful today.";
        System.out.printf("\nInput: \"%s\"\n", text);

        try (PiperPhonemize.Result result = PiperPhonemize.text(text)) {
            if (result != null) {
                System.out.printf("Sentences: %d\n", result.getNumSentences());
                for (int i = 0; i < result.getNumSentences(); i++) {
                    String ipa = result.getPhonemesAsString(i);
                    System.out.printf("  Sentence %d: %s\n", i + 1, ipa);
                }
            } else {
                System.out.println("Phonemization failed");
            }
        }
    }
}
