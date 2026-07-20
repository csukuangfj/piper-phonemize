# WASM support for piper-phonemize

if(PIPER_PHONEMIZE_ENABLE_WASM_NODEJS)
  add_subdirectory(nodejs)
endif()

if(PIPER_PHONEMIZE_ENABLE_WASM_BROWSER)
  add_subdirectory(browser)
endif()
