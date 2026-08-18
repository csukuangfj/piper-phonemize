// PiperPhonemize.kt
//
// Kotlin API for piper-phonemize (for Android)
//
// Copyright (c) 2026  Xiaomi Corporation

package com.github.csukuangfj.piper.phonemize

import android.content.Context
import java.io.File
import java.io.FileOutputStream

class PiperPhonemize {
    companion object {
        init {
            System.loadLibrary("piper-phonemize-jni")
        }

        val version: String
            get() = nativeGetVersionStr()

        @JvmStatic
        external fun nativeGetVersionStr(): String

        @JvmStatic
        external fun nativeInitialize(dataDir: String): Int

        @JvmStatic
        external fun nativeText(text: String, voice: String): Long

        @JvmStatic
        external fun nativeGetNumSentences(handle: Long): Int

        @JvmStatic
        external fun nativeGetNumPhonemes(handle: Long, sentenceId: Int): Int

        @JvmStatic
        external fun nativeGetPhonemes(handle: Long, sentenceId: Int): IntArray

        @JvmStatic
        external fun nativeDestroyResult(handle: Long)
    }
}

/**
 * Initialize piper-phonemize with an explicit data directory.
 */
fun piperPhonemizeInitialize(dataDir: String): Int {
    return PiperPhonemize.nativeInitialize(dataDir)
}

/**
 * Initialize piper-phonemize from Android assets.
 * Extracts espeak-ng-data from assets to internal storage on first call.
 */
fun piperPhonemizeInitialize(context: Context): Int {
    val dataDir = extractEspeakNgData(context)
    return piperPhonemizeInitialize(dataDir)
}

/**
 * Phonemize text.
 */
fun piperPhonemizeText(text: String, voice: String = "en-us"): PiperPhonemizeResult? {
    val handle = PiperPhonemize.nativeText(text, voice)
    if (handle == 0L) return null
    return PiperPhonemizeResult(handle)
}

/**
 * Result handle from phonemization.
 */
class PiperPhonemizeResult(private var handle: Long) {
    val numSentences: Int
        get() = PiperPhonemize.nativeGetNumSentences(handle)

    fun getNumPhonemes(sentenceId: Int): Int {
        return PiperPhonemize.nativeGetNumPhonemes(handle, sentenceId)
    }

    fun getPhonemes(sentenceId: Int): IntArray {
        return PiperPhonemize.nativeGetPhonemes(handle, sentenceId)
    }

    fun getPhonemesAsString(sentenceId: Int): String {
        val phonemes = getPhonemes(sentenceId)
        return String(phonemes.map { it.toChar() }.toCharArray())
    }

    fun getAllPhonemesAsStrings(): List<String> {
        return (0 until numSentences).map { getPhonemesAsString(it) }
    }

    fun close() {
        if (handle != 0L) {
            PiperPhonemize.nativeDestroyResult(handle)
            handle = 0L
        }
    }

    protected fun finalize() {
        close()
    }
}

private fun extractEspeakNgData(context: Context): String {
    val outputDir = File(context.filesDir, "espeak-ng-data")
    if (outputDir.exists() && outputDir.listFiles()?.isNotEmpty() == true) {
        return outputDir.absolutePath
    }

    outputDir.mkdirs()

    val assetManager = context.assets
    val files = assetManager.list("espeak-ng-data") ?: emptyArray()

    for (fileName in files) {
        val assetPath = "espeak-ng-data/$fileName"
        val outputFile = File(outputDir, fileName)

        if (!outputFile.exists()) {
            assetManager.open(assetPath).use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }
        }
    }

    return outputDir.absolutePath
}
