# WASM Browser target for piper-phonemize
#
# This builds a WASM module with espeak-ng-data preloaded.
# The output includes a demo HTML page.

if(NOT $ENV{PIPER_PHONEMIZE_IS_USING_BUILD_WASM_SH})
  message(FATAL_ERROR "Please use ./build-wasm-simd-browser.sh to build for wasm browser")
endif()

# Check that espeak-ng-data is present in assets/
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/assets/espeak-ng-data/phontab")
  message(FATAL_ERROR "espeak-ng-data not found in assets/espeak-ng-data/. Please see assets/README.md")
endif()

set(exported_functions
  PiperPhonemizeGetVersionStr
  PiperPhonemizeInitialize
  PiperPhonemizeText
  PiperPhonemizeResultGetNumSentences
  PiperPhonemizeResultGetNumPhonemes
  PiperPhonemizeResultGetPhonemes
  PiperPhonemizeDestroyResult
)
set(mangled_exported_functions)
foreach(x IN LISTS exported_functions)
  list(APPEND mangled_exported_functions "_${x}")
endforeach()
list(JOIN mangled_exported_functions "," all_exported_functions)

include_directories(${CMAKE_SOURCE_DIR}/src)

set(MY_FLAGS " -sFORCE_FILESYSTEM=1 -sINITIAL_MEMORY=256MB -sALLOW_MEMORY_GROWTH=1")
string(APPEND MY_FLAGS " -sSTACK_SIZE=10485760 ")  # 10MB
string(APPEND MY_FLAGS " -fexceptions ")
string(APPEND MY_FLAGS " -sEXPORTED_FUNCTIONS=[_malloc,_free,_CopyHeap,${all_exported_functions}] ")
string(APPEND MY_FLAGS " --preload-file ${CMAKE_CURRENT_SOURCE_DIR}/assets/espeak-ng-data@/usr/share/espeak-ng-data ")
string(APPEND MY_FLAGS " -sEXPORTED_RUNTIME_METHODS=['ccall','stringToUTF8','setValue','getValue','lengthBytesUTF8','UTF8ToString','HEAPU8','HEAP16','HEAP32','HEAPU32','HEAPF32','HEAPF64','addFunction','removeFunction'] ")

message(STATUS "WASM Browser flags: ${MY_FLAGS}")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${MY_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MY_FLAGS}")
set(CMAKE_EXECUTABLE_LINKER_FLAGS "${CMAKE_EXECUTABLE_LINKER_FLAGS} ${MY_FLAGS}")

if(NOT CMAKE_EXECUTABLE_SUFFIX STREQUAL ".js")
  message(FATAL_ERROR "The default suffix for building executables should be .js!")
endif()

add_executable(piper-phonemize-wasm-main piper-phonemize-wasm-main.cc)
target_link_libraries(piper-phonemize-wasm-main piper_phonemize_core)

install(TARGETS piper-phonemize-wasm-main DESTINATION bin/wasm/browser)
install(
  FILES
    "$<TARGET_FILE_DIR:piper-phonemize-wasm-main>/piper-phonemize-wasm-main.js"
    "$<TARGET_FILE_DIR:piper-phonemize-wasm-main>/piper-phonemize-wasm-main.wasm"
    "$<TARGET_FILE_DIR:piper-phonemize-wasm-main>/piper-phonemize-wasm-main.data"
    "${CMAKE_CURRENT_SOURCE_DIR}/piper-phonemize.js"
    "${CMAKE_CURRENT_SOURCE_DIR}/app-phonemize.js"
    "${CMAKE_CURRENT_SOURCE_DIR}/index.html"
  DESTINATION bin/wasm/browser
)
