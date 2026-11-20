// jni/jni.cc
//
// Copyright (c) 2026  Xiaomi Corporation

#include <jni.h>

#include <cstdint>
#include <string>

#include "c-api.h"

static std::string JStringToUtf8(JNIEnv *env, jstring s) {
  jsize n = env->GetStringLength(s);
  std::u16string u16(n, u'\0');
  env->GetStringRegion(s, 0, n, reinterpret_cast<jchar *>(&u16[0]));

  std::string result;
  for (size_t i = 0; i < u16.size(); ++i) {
    int32_t cp = u16[i];
    if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < u16.size() &&
        u16[i + 1] >= 0xDC00 && u16[i + 1] <= 0xDFFF) {
      cp = 0x10000 + ((cp - 0xD800) << 10) + (u16[i + 1] - 0xDC00);
      ++i;
    } else if (cp >= 0xD800 && cp <= 0xDFFF) {
      cp = 0xFFFD;
    }

    if (cp <= 0x7F) {
      result += static_cast<char>(cp);
    } else if (cp <= 0x7FF) {
      result += static_cast<char>(0xC0 | ((cp >> 6) & 0x1F));
      result += static_cast<char>(0x80 | (cp & 0x3F));
    } else if (cp <= 0xFFFF) {
      result += static_cast<char>(0xE0 | ((cp >> 12) & 0x0F));
      result += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
      result += static_cast<char>(0x80 | (cp & 0x3F));
    } else {
      result += static_cast<char>(0xF0 | ((cp >> 18) & 0x07));
      result += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
      result += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
      result += static_cast<char>(0x80 | (cp & 0x3F));
    }
  }
  return result;
}

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeGetVersionStr(
    JNIEnv *env, jclass /*cls*/) {
  const char *version = PiperPhonemizeGetVersionStr();
  return env->NewStringUTF(version);
}

JNIEXPORT jint JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeInitialize(
    JNIEnv *env, jclass /*cls*/, jstring data_dir) {
  std::string dir = JStringToUtf8(env, data_dir);
  return PiperPhonemizeInitialize(dir.c_str());
}

JNIEXPORT jlong JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeText(
    JNIEnv *env, jclass /*cls*/, jstring text, jstring voice) {
  std::string text_str = JStringToUtf8(env, text);
  std::string voice_str = JStringToUtf8(env, voice);

  PiperPhonemizeResult *result =
      PiperPhonemizeText(text_str.c_str(), voice_str.c_str());

  return reinterpret_cast<jlong>(result);
}

JNIEXPORT jint JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeGetNumSentences(
    JNIEnv *env, jclass /*cls*/, jlong handle) {
  auto *result = reinterpret_cast<PiperPhonemizeResult *>(handle);
  return PiperPhonemizeResultGetNumSentences(result);
}

JNIEXPORT jint JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeGetNumPhonemes(
    JNIEnv *env, jclass /*cls*/, jlong handle, jint sentence_id) {
  auto *result = reinterpret_cast<PiperPhonemizeResult *>(handle);
  return PiperPhonemizeResultGetNumPhonemes(result, sentence_id);
}

JNIEXPORT jintArray JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeGetPhonemes(
    JNIEnv *env, jclass /*cls*/, jlong handle, jint sentence_id) {
  auto *result = reinterpret_cast<PiperPhonemizeResult *>(handle);
  int32_t num_phonemes = PiperPhonemizeResultGetNumPhonemes(result, sentence_id);
  if (num_phonemes <= 0) {
    return env->NewIntArray(0);
  }

  const int32_t *phonemes =
      PiperPhonemizeResultGetPhonemes(result, sentence_id);
  if (phonemes == nullptr) {
    return env->NewIntArray(0);
  }

  jintArray ret = env->NewIntArray(num_phonemes);
  env->SetIntArrayRegion(ret, 0, num_phonemes,
                         reinterpret_cast<const jint *>(phonemes));
  return ret;
}

JNIEXPORT void JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeDestroyResult(
    JNIEnv *env, jclass /*cls*/, jlong handle) {
  auto *result = reinterpret_cast<PiperPhonemizeResult *>(handle);
  PiperPhonemizeDestroyResult(result);
}

}  // extern "C"
