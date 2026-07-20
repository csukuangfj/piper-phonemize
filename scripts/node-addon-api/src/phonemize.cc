// piper-phonemize node-addon-api
//
// Copyright (c) 2026  Xiaomi Corporation

#include "phonemize.h"

#include <string>

#include "c-api.h"

// initialize(dataDir: string) -> number
// Returns sample rate (22050) on success, -1 on failure
static Napi::Value Initialize(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (info.Length() < 1 || !info[0].IsString()) {
    Napi::TypeError::New(env, "String expected for dataDir")
        .ThrowAsJavaScriptException();
    return env.Null();
  }

  std::string dataDir = info[0].As<Napi::String>().Utf8Value();
  int32_t result = PiperPhonemizeInitialize(dataDir.c_str());
  return Napi::Number::New(env, result);
}

// getVersionStr() -> string
static Napi::Value GetVersionStr(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  const char *version = PiperPhonemizeGetVersionStr();
  return Napi::String::New(env, version);
}

// phonemize(text: string, voice: string) -> number[][] | null
// Returns array of sentences, each containing phoneme code points
static Napi::Value Phonemize(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  if (info.Length() < 1 || !info[0].IsString()) {
    Napi::TypeError::New(env, "String expected for text")
        .ThrowAsJavaScriptException();
    return env.Null();
  }

  std::string text = info[0].As<Napi::String>().Utf8Value();
  std::string voice = "en-us";

  if (info.Length() >= 2 && info[1].IsString()) {
    voice = info[1].As<Napi::String>().Utf8Value();
  }

  PiperPhonemizeResult *result =
      PiperPhonemizeText(text.c_str(), voice.c_str());

  if (!result) {
    return env.Null();
  }

  int32_t numSentences = PiperPhonemizeResultGetNumSentences(result);
  Napi::Array sentences = Napi::Array::New(env, numSentences);

  for (int32_t i = 0; i < numSentences; i++) {
    int32_t numPhonemes = PiperPhonemizeResultGetNumPhonemes(result, i);

    if (numPhonemes <= 0) {
      sentences.Set(i, Napi::Array::New(env, 0));
      continue;
    }

    const uint32_t *phonemes = PiperPhonemizeResultGetPhonemes(result, i);

    if (!phonemes) {
      sentences.Set(i, Napi::Array::New(env, 0));
      continue;
    }

    Napi::Array phonemeArray = Napi::Array::New(env, numPhonemes);
    for (int32_t j = 0; j < numPhonemes; j++) {
      phonemeArray.Set(j, Napi::Number::New(env, phonemes[j]));
    }
    sentences.Set(i, phonemeArray);
  }

  PiperPhonemizeDestroyResult(result);
  return sentences;
}

void InitPhonemize(Napi::Env env, Napi::Object exports) {
  exports.Set("initialize", Napi::Function::New(env, Initialize));
  exports.Set("getVersionStr", Napi::Function::New(env, GetVersionStr));
  exports.Set("phonemize", Napi::Function::New(env, Phonemize));
}
