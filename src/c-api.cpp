// piper-phonemize/src/c-api.cpp
//
// Copyright (c)  2022-2023  Xiaomi Corporation

#include "c-api.h"

#include <cstdint>
#include <mutex>
#include <string>
#include <vector>

#include "espeak-ng/speak_lib.h"
#include "phonemize.hpp"

struct PiperPhonemizeResult {
  std::vector<std::vector<piper::Phoneme>> phonemes;
};

static std::once_flag g_init_flag;

const char *PiperPhonemizeGetVersionStr() { return "1.5.9"; }

int32_t PiperPhonemizeInitialize(const char *data_dir) {
  int32_t result = 0;
  std::call_once(g_init_flag, [&]() {
    // espeakINITIALIZE_DONT_EXIT: on failure espeak_Initialize() would
    // otherwise call exit(1) and kill the host process/page. Return -1
    // instead so the caller can report the error.
    result = espeak_Initialize(AUDIO_OUTPUT_SYNCHRONOUS, 0, data_dir,
                               espeakINITIALIZE_DONT_EXIT);
    if (result <= 0) {
      // espeak may return 0 when its data files are missing; the documented
      // contract is -1 on failure.
      result = -1;
    }
  });
  return result;
}

PiperPhonemizeResult *PiperPhonemizeText(const char *text, const char *voice) {
  if (!text) {
    return nullptr;
  }

  auto *result = new PiperPhonemizeResult();

  if (text[0] == '\0') {
    return result;  // empty result with 0 sentences
  }

  piper::eSpeakPhonemeConfig config;
  if (voice && voice[0] != '\0') {
    config.voice = voice;
  }

  try {
    static std::mutex espeak_mutex;
    std::lock_guard<std::mutex> lock(espeak_mutex);
    piper::phonemize_eSpeak(std::string(text), config, result->phonemes);
  } catch (...) {
    delete result;
    return nullptr;
  }

  return result;
}

int32_t PiperPhonemizeResultGetNumSentences(
    const PiperPhonemizeResult *result) {
  if (!result) {
    return 0;
  }
  return static_cast<int32_t>(result->phonemes.size());
}

int32_t PiperPhonemizeResultGetNumPhonemes(const PiperPhonemizeResult *result,
                                           int32_t sentence_id) {
  if (!result || sentence_id < 0 ||
      sentence_id >= static_cast<int32_t>(result->phonemes.size())) {
    return -1;
  }
  return static_cast<int32_t>(result->phonemes[sentence_id].size());
}

const int32_t *PiperPhonemizeResultGetPhonemes(
    const PiperPhonemizeResult *result, int32_t sentence_id) {
  if (!result || sentence_id < 0 ||
      sentence_id >= static_cast<int32_t>(result->phonemes.size())) {
    return nullptr;
  }
  if (result->phonemes[sentence_id].empty()) {
    return nullptr;
  }
  return reinterpret_cast<const int32_t *>(
      result->phonemes[sentence_id].data());
}

void PiperPhonemizeDestroyResult(PiperPhonemizeResult *result) {
  delete result;
}
