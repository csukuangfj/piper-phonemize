// jni/jni.cc
//
// Copyright (c) 2026  Xiaomi Corporation

#include <jni.h>

#include <cstdint>
#include <string>

#include "c-api.h"

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
  const char *dir = env->GetStringUTFChars(data_dir, nullptr);
  int32_t result = PiperPhonemizeInitialize(dir);
  env->ReleaseStringUTFChars(data_dir, dir);
  return result;
}

JNIEXPORT jlong JNICALL
Java_com_github_csukuangfj_piper_phonemize_PiperPhonemize_nativeText(
    JNIEnv *env, jclass /*cls*/, jstring text, jstring voice) {
  const char *text_str = env->GetStringUTFChars(text, nullptr);
  const char *voice_str = env->GetStringUTFChars(voice, nullptr);

  PiperPhonemizeResult *result = PiperPhonemizeText(text_str, voice_str);

  env->ReleaseStringUTFChars(text, text_str);
  env->ReleaseStringUTFChars(voice, voice_str);

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

  const uint32_t *phonemes =
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
