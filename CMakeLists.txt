cmake_minimum_required(VERSION 3.14)

set(CMAKE_VERBOSE_MAKEFILE off)

project(
    piper_phonemize
    VERSION 1.2.0
    DESCRIPTION "Phonemization library for Piper text to speech system"
    HOMEPAGE_URL "https://github.com/rhasspy/piper-phonemize"
    LANGUAGES CXX
)

if(MSVC)
    # Force compiler to use UTF-8 for IPA constants
    add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
    add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")

elseif(NOT APPLE)
    # Linux flags
    string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra ")
    string(APPEND CMAKE_C_FLAGS " -Wall -Wextra")
endif()

option(BUILD_SHARED_LIBS "Whether to build shared libraries" ON)
option(BUILD_PIPER_PHONMIZE_EXE "Whether to build piper_phonemize_exe" ON)
option(BUILD_PIPER_PHONMIZE_TESTS "Whether to build tests" ON)
option(ENABLE_PIPER_PHONMIZE_SONAME "Whether to enable soname" ON)

add_library(
    piper_phonemize
    src/phonemize.cpp
    src/phoneme_ids.cpp
    src/shared.cpp
)

if(ENABLE_PIPER_PHONMIZE_SONAME)
  set_target_properties(piper_phonemize PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
  )
endif()


# ---- espeak-ng ---

if(NOT DEFINED ESPEAK_NG_DIR)
    set(ESPEAK_NG_DIR "${CMAKE_CURRENT_BINARY_DIR}/ei")

    include(ExternalProject)
    ExternalProject_Add(
        espeak_ng_external
        PREFIX "${CMAKE_CURRENT_BINARY_DIR}/e"
        # URL "https://github.com/rhasspy/espeak-ng/archive/refs/heads/master.zip"
        URL "https://github.com/csukuangfj/espeak-ng/archive/7251208ee427ef87e94f39d0e99b15d287224ed6.zip"
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
        CMAKE_ARGS -DUSE_ASYNC:BOOL=OFF
        CMAKE_ARGS -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
        CMAKE_ARGS -DUSE_MBROLA:BOOL=OFF
        CMAKE_ARGS -DUSE_LIBSONIC:BOOL=OFF
        CMAKE_ARGS -DUSE_LIBPCAUDIO:BOOL=OFF
        CMAKE_ARGS -DBUILD_ESPEAK_NG_EXE:BOOL=OFF
        CMAKE_ARGS -DBUILD_ESPEAK_NG_TESTS:BOOL=OFF
        CMAKE_ARGS -DUSE_KLATT:BOOL=OFF
        CMAKE_ARGS -DUSE_SPEECHPLAYER:BOOL=OFF
        CMAKE_ARGS -DEXTRA_cmn:BOOL=ON
        CMAKE_ARGS -DEXTRA_ru:BOOL=ON
        CMAKE_ARGS -DCMAKE_C_FLAGS="-D_FILE_OFFSET_BITS=64"
    )
    add_dependencies(piper_phonemize espeak_ng_external)
endif()

# ---- Declare library ----

target_include_directories(
    piper_phonemize PUBLIC
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>"
    ${ESPEAK_NG_DIR}/include
    ${ONNXRUNTIME_DIR}/include
)

if(DEFINED ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR})
  target_include_directories(
      piper_phonemize PUBLIC
      $ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR}
  )
endif()

if(EXISTS ${ESPEAK_NG_DIR}/lib)
  target_link_directories(
      piper_phonemize PUBLIC
      ${ESPEAK_NG_DIR}/lib
  )
endif()

target_link_libraries(
    piper_phonemize
    espeak-ng
)

if(NOT BUILD_SHARED_LIBS)
  target_link_libraries(piper_phonemize ucd)
endif()

target_compile_features(piper_phonemize PUBLIC cxx_std_17)

# ---- Declare install targets ----

include(GNUInstallDirs)

install(
    TARGETS piper_phonemize
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(
    DIRECTORY ${CMAKE_SOURCE_DIR}/src/
    DESTINATION include/piper-phonemize
    FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.hpp")

if(EXISTS ${ESPEAK_NG_DIR})
  # Dependencies
  install(
      DIRECTORY ${ESPEAK_NG_DIR}/
      DESTINATION ${CMAKE_INSTALL_PREFIX})
endif()
