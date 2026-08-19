// Copyright 2026 Xiaomi Corporation

import com.github.csukuangfj.piper.phonemize.*

fun main() {
    println("piper-phonemize version: ${PiperPhonemize.version}")

    val sampleRate = piperPhonemizeInitialize("/path/to/espeak-ng-data")
    println("Sample rate: $sampleRate")

    val text = "Hello world. This is a test. The weather is beautiful today."
    println("\nInput: \"$text\"")

    val result = piperPhonemizeText(text)
    if (result != null) {
        println("Sentences: ${result.numSentences}")
        for (i in 0 until result.numSentences) {
            val ipa = result.getPhonemesAsString(i)
            println("  Sentence ${i + 1}: $ipa")
        }
        result.close()
    }
}
