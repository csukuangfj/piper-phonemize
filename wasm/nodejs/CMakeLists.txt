# WASM Node.js target for piper-phonemize

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
string(APPEND MY_FLAGS " -sMODULARIZE=1 ")
string(APPEND MY_FLAGS " -sWASM_ASYNC_COMPILATION=0 ")
string(APPEND MY_FLAGS " -sNODERAWFS=1 ")
string(APPEND MY_FLAGS " -fexceptions ")
string(APPEND MY_FLAGS " -sEXPORTED_FUNCTIONS=[_malloc,_free,${all_exported_functions}] ")
string(APPEND MY_FLAGS " -sEXPORTED_RUNTIME_METHODS=['ccall','stringToUTF8','setValue','getValue','lengthBytesUTF8','UTF8ToString','HEAPU8','HEAP16','HEAP32','HEAPU32','HEAPF32','HEAPF64','addFunction','removeFunction'] ")

message(STATUS "WASM Node.js flags: ${MY_FLAGS}")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${MY_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MY_FLAGS}")
set(CMAKE_EXECUTABLE_LINKER_FLAGS "${CMAKE_EXECUTABLE_LINKER_FLAGS} ${MY_FLAGS}")

if(NOT CMAKE_EXECUTABLE_SUFFIX STREQUAL ".js")
  message(FATAL_ERROR "The default suffix for building executables should be .js!")
endif()

add_executable(piper-phonemize-wasm-nodejs piper-phonemize-wasm-nodejs.cc)
target_link_libraries(piper-phonemize-wasm-nodejs piper_phonemize_core)

install(TARGETS piper-phonemize-wasm-nodejs DESTINATION bin/wasm/nodejs)
install(
  FILES
    "$<TARGET_FILE_DIR:piper-phonemize-wasm-nodejs>/piper-phonemize-wasm-nodejs.js"
    "$<TARGET_FILE_DIR:piper-phonemize-wasm-nodejs>/piper-phonemize-wasm-nodejs.wasm"
    "${CMAKE_CURRENT_SOURCE_DIR}/piper-phonemize.node.js"
  DESTINATION bin/wasm/nodejs
)
