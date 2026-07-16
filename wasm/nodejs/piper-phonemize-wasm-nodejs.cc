// wasm/nodejs/piper-phonemize-wasm-nodejs.cc
//
// WASM glue for piper-phonemize C API (Node.js target)
//
// Copyright (c) 2026  Xiaomi Corporation

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "c-api.h"

extern "C" {

// Helper to copy data from WASM heap (useful for JS wrappers)
void CopyHeap(void *dst, const void *src, int32_t size) {
  memcpy(dst, src, size);
}

// Debug helper to print version
void PrintVersion() {
  fprintf(stdout, "piper-phonemize version: %s\n",
          PiperPhonemizeGetVersionStr());
}

}  // extern "C"
