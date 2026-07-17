// piper-phonemize node-addon-api entry point
//
// Copyright (c) 2026  Xiaomi Corporation

#include <napi.h>
#include "phonemize.h"

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  InitPhonemize(env, exports);
  return exports;
}

NODE_API_MODULE(addon, Init)
