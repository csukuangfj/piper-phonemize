// piper-phonemize/src/cxx-api.cc
//
// Copyright (c)  2026  Xiaomi Corporation

#include "cxx-api.h"

#include <cstdint>
#include <string>
#include <vector>

namespace piper_phonemize::cxx {

PIPER_PHONEMIZE_API int32_t Initialize(const std::string &data_dir) {
  return PiperPhonemizeInitialize(data_dir.c_str());
}

PIPER_PHONEMIZE_API PhonemizeResult Phonemize(const std::string &text,
                                               const std::string &voice /*= ""*/) {
  PhonemizeResult result;

  PiperPhonemizeResult *c_result =
      PiperPhonemizeText(text.c_str(), voice.c_str());
  if (!c_result) {
    return result;
  }

  int32_t num_sentences = PiperPhonemizeResultGetNumSentences(c_result);
  result.sentences.resize(num_sentences);

  for (int32_t i = 0; i < num_sentences; ++i) {
    int32_t n = PiperPhonemizeResultGetNumPhonemes(c_result, i);
    if (n <= 0) {
      continue;
    }
    const uint32_t *phonemes = PiperPhonemizeResultGetPhonemes(c_result, i);
    if (phonemes) {
      result.sentences[i].assign(phonemes, phonemes + n);
    }
  }

  PiperPhonemizeDestroyResult(c_result);
  return result;
}

PIPER_PHONEMIZE_API std::string GetVersionStr() {
  return PiperPhonemizeGetVersionStr();
}

}  // namespace piper_phonemize::cxx
