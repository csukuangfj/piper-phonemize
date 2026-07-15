// piper-phonemize/src/cxx-api.h
//
// Copyright (c)  2026  Xiaomi Corporation
/**
 * @file cxx-api.h
 * @brief Public C++ wrapper for the piper-phonemize C API.
 *
 * This header provides a lightweight C++ interface on top of `c-api.h`. The
 * wrapper follows a few simple design rules:
 *
 * - Result objects are copied into standard C++ containers so callers do not
 *   need to manage C-allocated memory manually
 * - The API mirrors the C API closely, while offering a more idiomatic C++
 *   surface
 *
 * Typical usage pattern:
 *
 * 1. Call `Initialize()` once with the path to espeak-ng-data
 * 2. Call `Phonemize()` to convert text to phonemes
 * 3. Access the phonemes via the returned value object
 *
 * Example:
 *
 * @code
 * #include "cxx-api.h"
 *
 * namespace pp = piper_phonemize::cxx;
 *
 * pp::Initialize("./espeak-ng-data");
 * auto result = pp::Phonemize("hello world", "en-us");
 * for (const auto &sentence : result.sentences) {
 *   for (uint32_t phoneme : sentence) {
 *     // process phoneme codepoint
 *   }
 * }
 * @endcode
 */
#ifndef PIPER_PHONEMIZE_CXX_API_H_
#define PIPER_PHONEMIZE_CXX_API_H_

#include <cstdint>
#include <string>
#include <vector>

#include "c-api.h"

namespace piper_phonemize::cxx {

// ============================================================================
// Helper types
// ============================================================================

/**
 * @brief Result of phonemization, copied into C++ containers.
 *
 * Each element of `sentences` is a vector of Unicode code points representing
 * the phonemes for one sentence.
 */
struct PhonemizeResult {
  /** Phoneme sequences, one vector per sentence. */
  std::vector<std::vector<uint32_t>> sentences;
};

/**
 * @brief Initialize espeak-ng.
 *
 * This must be called before any phonemization functions.
 * It is safe to call multiple times; only the first call takes effect.
 *
 * @param data_dir  Path to the espeak-ng-data directory.
 * @return Sample rate in Hz (22050) on success, or -1 on failure.
 */
PIPER_PHONEMIZE_API int32_t Initialize(const std::string &data_dir);

/**
 * @brief Phonemize text using espeak-ng.
 *
 * @param text   The text to phonemize (UTF-8).
 * @param voice  The espeak-ng voice to use (e.g. "en-us").
 *               Pass "" to use the default "en-us".
 * @return A PhonemizeResult with the phonemes copied into C++ containers.
 *         Returns an empty result (0 sentences) on failure or empty input.
 */
PIPER_PHONEMIZE_API PhonemizeResult Phonemize(const std::string &text,
                                               const std::string &voice = "");

/**
 * @brief Return the piper-phonemize version string.
 *
 * @return Version string, for example `"1.4.3"`.
 */
PIPER_PHONEMIZE_API std::string GetVersionStr();

}  // namespace piper_phonemize::cxx

#endif  // PIPER_PHONEMIZE_CXX_API_H_
