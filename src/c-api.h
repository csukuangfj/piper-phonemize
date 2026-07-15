// piper-phonemize/src/c-api.h
//
// Copyright (c)  2026  Xiaomi Corporation

#ifndef PIPER_PHONEMIZE_C_API_H_
#define PIPER_PHONEMIZE_C_API_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// See https://github.com/pytorch/pytorch/blob/main/c10/macros/Export.h

#if defined(_WIN32)
#if defined(PIPER_PHONEMIZE_BUILD_SHARED_LIBS)
#define PIPER_PHONEMIZE_EXPORT __declspec(dllexport)
#define PIPER_PHONEMIZE_IMPORT __declspec(dllimport)
#else
#define PIPER_PHONEMIZE_EXPORT
#define PIPER_PHONEMIZE_IMPORT
#endif
#else  // WIN32
#define PIPER_PHONEMIZE_EXPORT __attribute__((visibility("default")))
#define PIPER_PHONEMIZE_IMPORT PIPER_PHONEMIZE_EXPORT
#endif  // WIN32

#if defined(PIPER_PHONEMIZE_BUILD_MAIN_LIB)
#define PIPER_PHONEMIZE_API PIPER_PHONEMIZE_EXPORT
#else
#define PIPER_PHONEMIZE_API PIPER_PHONEMIZE_IMPORT
#endif

/**
 * @brief Return the piper-phonemize version string.
 *
 * The returned pointer refers to statically allocated memory owned by the
 * library. Do not free it and do not modify it.
 *
 * @return Version string, for example `"1.4.3"`.
 */
PIPER_PHONEMIZE_API const char *PiperPhonemizeGetVersionStr();

/** Opaque handle for the phonemize result. */
typedef struct PiperPhonemizeResult PiperPhonemizeResult;

/**
 * @brief Initialize espeak-ng.
 *
 * This must be called before any phonemization functions.
 * It is safe to call multiple times; only the first call takes effect.
 *
 * @param data_dir  Path to the espeak-ng-data directory.
 * @return Sample rate in Hz (22050) on success, or -1 on failure.
 */
PIPER_PHONEMIZE_API int32_t PiperPhonemizeInitialize(const char *data_dir);

/**
 * @brief Phonemize text using espeak-ng.
 *
 * The caller is responsible for freeing the result with
 * PiperPhonemizeDestroyResult().
 *
 * @param text   The text to phonemize (UTF-8).
 * @param voice  The espeak-ng voice to use (e.g. "en-us").
 *               Pass "" or NULL to use the default "en-us".
 * @return An opaque result handle, or NULL on failure.
 */
PIPER_PHONEMIZE_API PiperPhonemizeResult *PiperPhonemizeText(const char *text,
                                                             const char *voice);

/**
 * @brief Get the number of sentences in the result.
 *
 * Each sentence corresponds to a separate vector of phonemes.
 *
 * @param result  A valid result handle.
 * @return The number of sentences.
 */
PIPER_PHONEMIZE_API int32_t
PiperPhonemizeResultGetNumSentences(const PiperPhonemizeResult *result);

/**
 * @brief Get the number of phonemes in a given sentence.
 *
 * @param result      A valid result handle.
 * @param sentence_id  Zero-based sentence index.
 * @return The number of phonemes in the sentence, or -1 if sentence_id
 *         is out of range.
 */
PIPER_PHONEMIZE_API int32_t PiperPhonemizeResultGetNumPhonemes(
    const PiperPhonemizeResult *result, int32_t sentence_id);

/**
 * @brief Get a pointer to the phoneme array for a given sentence.
 *
 * Each phoneme is a char32_t (uint32_t) Unicode code point.
 * The returned pointer is valid for the lifetime of the result handle.
 *
 * @param result      A valid result handle.
 * @param sentence_id  Zero-based sentence index.
 * @return Pointer to the phoneme array, or NULL if sentence_id is out of
 *         range.
 */
PIPER_PHONEMIZE_API const uint32_t *PiperPhonemizeResultGetPhonemes(
    const PiperPhonemizeResult *result, int32_t sentence_id);

/**
 * @brief Free a result handle.
 *
 * @param result  A valid result handle, or NULL.
 */
PIPER_PHONEMIZE_API void PiperPhonemizeDestroyResult(
    PiperPhonemizeResult *result);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // PIPER_PHONEMIZE_C_API_H_
