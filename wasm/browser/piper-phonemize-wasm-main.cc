// wasm/browser/piper-phonemize-wasm-main.cc
//
// WASM glue for piper-phonemize C API (Browser target)
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

}  // extern "C"
