// piper-phonemize/src/test-cxx-api.cpp
//
// Copyright (c)  2026  Xiaomi Corporation

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#include "cxx-api.h"

static int num_errors = 0;

static std::string CodepointToUtf8(uint32_t cp) {
  std::string result;
  if (cp <= 0x7F) {
    result += static_cast<char>(cp);
  } else if (cp <= 0x7FF) {
    result += static_cast<char>(0xC0 | ((cp >> 6) & 0x1F));
    result += static_cast<char>(0x80 | (cp & 0x3F));
  } else if (cp <= 0xFFFF) {
    result += static_cast<char>(0xE0 | ((cp >> 12) & 0x0F));
    result += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
    result += static_cast<char>(0x80 | (cp & 0x3F));
  } else if (cp <= 0x10FFFF) {
    result += static_cast<char>(0xF0 | ((cp >> 18) & 0x07));
    result += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
    result += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
    result += static_cast<char>(0x80 | (cp & 0x3F));
  }
  return result;
}

static std::string PhonemesToString(const std::vector<uint32_t> &phonemes) {
  std::string s;
  for (uint32_t cp : phonemes) {
    s += CodepointToUtf8(cp);
  }
  return s;
}

#define CHECK(cond, msg)                                                 \
  do {                                                                   \
    if (!(cond)) {                                                       \
      fprintf(stderr, "FAIL: %s (line %d): %s\n", msg, __LINE__, #cond); \
      ++num_errors;                                                      \
    }                                                                    \
  } while (0)

static void PrintResult(const char *text,
                        const piper_phonemize::cxx::PhonemizeResult &result) {
  printf("  text: \"%s\"\n", text);
  for (size_t i = 0; i < result.sentences.size(); ++i) {
    printf("    sentence %zu: %s\n", i,
           PhonemesToString(result.sentences[i]).c_str());
  }
}

// --------------------------------------------------------------------------

static void test_version() {
  printf("test_version:\n");
  std::string v = piper_phonemize::cxx::GetVersionStr();
  CHECK(!v.empty(), "version string is non-empty");
  printf("  version: %s\n", v.c_str());
}

static void test_initialize(const char *data_dir) {
  printf("test_initialize:\n");
  int32_t result = piper_phonemize::cxx::Initialize(data_dir);
  CHECK(result == 22050, "Initialize returns 22050 on success");
}

// --------------------------------------------------------------------------

static void test_english_basic() {
  printf("test_english_basic:\n");

  const char *text1 = "hello";
  auto result = piper_phonemize::cxx::Phonemize(text1, "en-us");
  CHECK(!result.sentences.empty(), "'hello' has at least 1 sentence");
  PrintResult(text1, result);

  const char *text2 =
      "The quick brown fox jumps over the lazy dog. "
      "Pack my box with five dozen liquor jugs. "
      "How vexingly quick daft zebras jump.";
  result = piper_phonemize::cxx::Phonemize(text2, "en-us");
  CHECK(result.sentences.size() >= 3, "at least 3 sentences");
  PrintResult(text2, result);
}

static void test_punctuation() {
  printf("test_punctuation:\n");

  const char *text = "this, is: a; test.";
  auto result = piper_phonemize::cxx::Phonemize(text, "en-us");
  CHECK(!result.sentences.empty(), "punctuation returns non-empty");
  PrintResult(text, result);
}

static void test_sentence_splitting() {
  printf("test_sentence_splitting:\n");

  const char *text = "Test one. Test two. Test three.";
  auto result = piper_phonemize::cxx::Phonemize(text, "en-us");
  CHECK(result.sentences.size() == 3, "3 sentences expected");
  PrintResult(text, result);
}

static void test_german() {
  printf("test_german:\n");

  const char *text1 = "licht!";
  auto result = piper_phonemize::cxx::Phonemize(text1, "de");
  CHECK(!result.sentences.empty(), "German 'licht!' returns non-empty");
  PrintResult(text1, result);

  const char *text2 =
      "Guten Morgen, wie geht es Ihnen? "
      "Danke, mir geht es sehr gut. "
      "Das Wetter ist heute schön!";
  result = piper_phonemize::cxx::Phonemize(text2, "de");
  CHECK(result.sentences.size() >= 3, "German has at least 3 sentences");
  PrintResult(text2, result);
}

static void test_french() {
  printf("test_french:\n");

  const char *text =
      "Bonjour, comment allez-vous? "
      "Je vais très bien, merci! "
      "Le français est une belle langue.";
  auto result = piper_phonemize::cxx::Phonemize(text, "fr");
  CHECK(result.sentences.size() >= 3, "French has at least 3 sentences");
  PrintResult(text, result);
}

static void test_chinese_pinyin() {
  printf("test_chinese_pinyin:\n");

  const char *text = "你好世界。今天天气很好。我很高兴认识你。";
  auto result = piper_phonemize::cxx::Phonemize(text, "cmn");
  CHECK(!result.sentences.empty(), "Chinese returns non-empty");
  PrintResult(text, result);
}

static void test_russian() {
  printf("test_russian:\n");

  const char *text =
      "Привет, мир! "
      "Как у тебя дела? "
      "Сегодня хорошая погода.";
  auto result = piper_phonemize::cxx::Phonemize(text, "ru");
  CHECK(result.sentences.size() >= 3, "Russian has at least 3 sentences");
  PrintResult(text, result);
}

static void test_empty_and_null() {
  printf("test_empty_and_null:\n");

  auto result = piper_phonemize::cxx::Phonemize("", "en-us");
  CHECK(result.sentences.empty(), "empty string has 0 sentences");

  result = piper_phonemize::cxx::Phonemize("   ", "en-us");
  // whitespace-only input: espeak may or may not produce output
  printf("  whitespace-only: %zu sentence(s)\n", result.sentences.size());
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <espeak-ng-data-dir>\n", argv[0]);
    return 1;
  }

  printf("Testing piper-phonemize C++ API\n\n");

  test_version();
  test_initialize(argv[1]);
  test_english_basic();
  test_punctuation();
  test_sentence_splitting();
  test_german();
  test_french();
  test_chinese_pinyin();
  test_russian();
  test_empty_and_null();

  if (num_errors == 0) {
    printf("\nAll tests passed.\n");
    return 0;
  } else {
    printf("\n%d test(s) failed.\n", num_errors);
    return 1;
  }
}
