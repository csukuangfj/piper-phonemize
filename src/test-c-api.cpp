// piper-phonemize/src/test-c-api.cpp
//
// Copyright (c)  2022-2023  Xiaomi Corporation

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#include "c-api.h"

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

static std::string PhonemesToString(const PiperPhonemizeResult *result,
                                    int32_t sentence_id) {
  std::string s;
  int32_t n = PiperPhonemizeResultGetNumPhonemes(result, sentence_id);
  const uint32_t *phonemes = PiperPhonemizeResultGetPhonemes(result, sentence_id);
  if (phonemes) {
    for (int32_t j = 0; j < n; ++j) {
      s += CodepointToUtf8(phonemes[j]);
    }
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

static void PrintResult(const PiperPhonemizeResult *result) {
  int32_t num_sentences = PiperPhonemizeResultGetNumSentences(result);
  for (int32_t i = 0; i < num_sentences; ++i) {
    printf("    sentence %d: %s\n", i, PhonemesToString(result, i).c_str());
  }
}

// --------------------------------------------------------------------------

static void test_version() {
  printf("test_version:\n");
  const char *v = PiperPhonemizeGetVersionStr();
  CHECK(v != nullptr, "version string is not null");
  CHECK(strlen(v) > 0, "version string is non-empty");
  printf("  version: %s\n", v);
}

static void test_initialize(const char *data_dir) {
  printf("test_initialize:\n");
  int32_t result = PiperPhonemizeInitialize(data_dir);
  CHECK(result == 22050, "espeak_Initialize returns 22050 on success");
}

// --------------------------------------------------------------------------

static void test_english_basic() {
  printf("test_english_basic:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText("hello", "en-us");
  CHECK(result != nullptr, "'hello' returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 1,
        "'hello' has at least 1 sentence");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);

  // Multiple sentences
  result = PiperPhonemizeText(
      "The quick brown fox jumps over the lazy dog. "
      "Pack my box with five dozen liquor jugs. "
      "How vexingly quick daft zebras jump.",
      "en-us");
  CHECK(result != nullptr, "multi-sentence English returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "at least 3 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);

  // British English
  result = PiperPhonemizeText(
      "The colour of the harbour is beautiful. "
      "He organised the theatre programme.",
      "en");
  CHECK(result != nullptr, "British English returns non-null");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_punctuation() {
  printf("test_punctuation:\n");

  PiperPhonemizeResult *result =
      PiperPhonemizeText("this, is: a; test.", "en-us");
  CHECK(result != nullptr, "punctuation returns non-null");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);

  result = PiperPhonemizeText(
      "Hello! How are you? I'm fine, thanks. "
      "The price is $3.50; not bad, right? "
      "Yes: it's a great deal!",
      "en-us");
  CHECK(result != nullptr, "mixed punctuation returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "multiple sentences split on . ? !");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_sentence_splitting() {
  printf("test_sentence_splitting:\n");

  // Capitalization is required for espeak to split sentences
  PiperPhonemizeResult *result =
      PiperPhonemizeText("Test one. Test two. Test three.", "en-us");
  CHECK(result != nullptr, "3 sentences returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) == 3,
        "3 sentences expected");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_german() {
  printf("test_german:\n");

  // "licht" has the ç phoneme (decomposed into two codepoints)
  PiperPhonemizeResult *result = PiperPhonemizeText("licht!", "de");
  CHECK(result != nullptr, "German 'licht!' returns non-null");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);

  result = PiperPhonemizeText(
      "Guten Morgen, wie geht es Ihnen? "
      "Danke, mir geht es sehr gut. "
      "Das Wetter ist heute schön!",
      "de");
  CHECK(result != nullptr, "German multi-sentence returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "German has at least 3 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_french() {
  printf("test_french:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText(
      "Bonjour, comment allez-vous? "
      "Je vais très bien, merci! "
      "Le français est une belle langue.",
      "fr");
  CHECK(result != nullptr, "French multi-sentence returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "French has at least 3 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_spanish() {
  printf("test_spanish:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText(
      "Buenos días, ¿cómo estás? "
      "Muy bien, gracias! "
      "El español es un idioma muy bonito.",
      "es");
  CHECK(result != nullptr, "Spanish multi-sentence returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "Spanish has at least 3 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_chinese_pinyin() {
  printf("test_chinese_pinyin:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText(
      "你好世界。今天天气很好。我很高兴认识你。",
      "cmn");
  CHECK(result != nullptr, "Chinese multi-sentence returns non-null");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_russian() {
  printf("test_russian:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText(
      "Привет, мир! "
      "Как у тебя дела? "
      "Сегодня хорошая погода.",
      "ru");
  CHECK(result != nullptr, "Russian multi-sentence returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "Russian has at least 3 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_numbers() {
  printf("test_numbers:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText(
      "I have 42 apples and 3.14 pies. "
      "The year is 2025. "
      "Call me at 555-1234. "
      "The price is $9.99!",
      "en-us");
  CHECK(result != nullptr, "numbers in text returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 4,
        "numbers text has at least 4 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_special_characters() {
  printf("test_special_characters:\n");

  // Contractions and hyphenated words
  PiperPhonemizeResult *result = PiperPhonemizeText(
      "I can't believe it! Don't you agree? "
      "The well-known scientist won't attend. "
      "She said: 'It's a twenty-one day trip.'",
      "en-us");
  CHECK(result != nullptr, "contractions and hyphens returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "special chars has at least 3 sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_empty_and_whitespace() {
  printf("test_empty_and_whitespace:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText("", "en-us");
  CHECK(result != nullptr, "empty string returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) == 0,
        "empty string has 0 sentences");
  PiperPhonemizeDestroyResult(result);

  result = PiperPhonemizeText("   ", "en-us");
  CHECK(result != nullptr, "whitespace-only returns non-null");
  PiperPhonemizeDestroyResult(result);
}

static void test_long_text() {
  printf("test_long_text:\n");

  PiperPhonemizeResult *result = PiperPhonemizeText(
      "In the beginning God created the heaven and the earth. "
      "And the earth was without form, and void; and darkness was upon "
      "the face of the deep. And the Spirit of God moved upon the face "
      "of the waters. And God said, Let there be light: and there was light.",
      "en-us");
  CHECK(result != nullptr, "long text returns non-null");
  CHECK(PiperPhonemizeResultGetNumSentences(result) >= 3,
        "long text has multiple sentences");
  PrintResult(result);
  PiperPhonemizeDestroyResult(result);
}

static void test_null_handling() {
  printf("test_null_handling:\n");

  // NULL text
  PiperPhonemizeResult *r1 = PiperPhonemizeText(nullptr, "en-us");
  CHECK(r1 == nullptr, "NULL text returns nullptr");

  // NULL voice should use default
  PiperPhonemizeResult *r2 = PiperPhonemizeText("hello", nullptr);
  CHECK(r2 != nullptr, "NULL voice returns non-null (uses default)");
  PiperPhonemizeDestroyResult(r2);

  // Empty voice should use default
  PiperPhonemizeResult *r3 = PiperPhonemizeText("hello", "");
  CHECK(r3 != nullptr, "empty voice returns non-null (uses default)");
  PiperPhonemizeDestroyResult(r3);

  // NULL result for query functions
  CHECK(PiperPhonemizeResultGetNumSentences(nullptr) == 0,
        "null result returns 0 sentences");
  CHECK(PiperPhonemizeResultGetNumPhonemes(nullptr, 0) == -1,
        "null result returns -1 phonemes");
  CHECK(PiperPhonemizeResultGetPhonemes(nullptr, 0) == nullptr,
        "null result returns null phonemes");

  // Out-of-range sentence id
  PiperPhonemizeResult *r4 = PiperPhonemizeText("hello", "en-us");
  CHECK(PiperPhonemizeResultGetNumPhonemes(r4, 999) == -1,
        "out-of-range sentence returns -1");
  CHECK(PiperPhonemizeResultGetPhonemes(r4, 999) == nullptr,
        "out-of-range sentence returns null");
  CHECK(PiperPhonemizeResultGetNumPhonemes(r4, -1) == -1,
        "negative sentence id returns -1");

  PiperPhonemizeDestroyResult(r4);

  // Destroying NULL is safe
  PiperPhonemizeDestroyResult(nullptr);
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <espeak-ng-data-dir>\n", argv[0]);
    return 1;
  }

  printf("Testing piper-phonemize C API\n\n");

  test_version();
  test_initialize(argv[1]);
  test_english_basic();
  test_punctuation();
  test_sentence_splitting();
  test_german();
  test_french();
  test_spanish();
  test_chinese_pinyin();
  test_russian();
  test_numbers();
  test_special_characters();
  test_empty_and_whitespace();
  test_long_text();
  test_null_handling();

  if (num_errors == 0) {
    printf("\nAll tests passed.\n");
    return 0;
  } else {
    printf("\n%d test(s) failed.\n", num_errors);
    return 1;
  }
}
