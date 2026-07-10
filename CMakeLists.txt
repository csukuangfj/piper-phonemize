if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
  cmake_policy(SET CMP0135 NEW)
endif()

cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# https://cmake.org/cmake/help/latest/prop_tgt/MSVC_RUNTIME_LIBRARY.html
cmake_policy(SET CMP0091 NEW)

set(CMAKE_VERBOSE_MAKEFILE off)

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.14" CACHE STRING "Minimum OS X deployment version. Used only for macOS")

project(
    piper_phonemize
    VERSION 1.2.0
    DESCRIPTION "Phonemization library for Piper text to speech system"
    HOMEPAGE_URL "https://github.com/rhasspy/piper-phonemize"
    LANGUAGES C CXX
)

# ---- Cross-platform build settings (following sherpa-onnx) ----

option(PIPER_PHONEMIZE_USE_STATIC_CRT "For Windows only. ON to use static CRT (/MT /MTd); OFF to use dynamic (/MD /MDd)" ON)

# On Windows with MSVC, explicitly control which C runtime (CRT) to use.
if(MSVC AND NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
  if(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "")
    if(PIPER_PHONEMIZE_USE_STATIC_CRT)
      if(CMAKE_BUILD_TYPE MATCHES Debug)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDebug")
      else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")
      endif()
    else()
      if(CMAKE_BUILD_TYPE MATCHES Debug)
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDebugDLL")
      else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
      endif()
    endif()
  else()
    if(PIPER_PHONEMIZE_USE_STATIC_CRT)
      set(CMAKE_MSVC_RUNTIME_LIBRARY
          "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
      set(CMAKE_MSVC_RUNTIME_LIBRARY
          "MultiThreadedDLL$<$<CONFIG:Debug>:Debug>")
    endif()
  endif()
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

if(UNIX)
  set(CMAKE_SKIP_BUILD_RPATH FALSE)
  set(BUILD_RPATH_USE_ORIGIN TRUE)
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()

if(NOT APPLE)
  set(PIPER_PHONEMIZE_RPATH_ORIGIN "$ORIGIN")
  set(PIPER_PHONEMIZE_RPATH_ORIGIN_PARENT "$ORIGIN/../lib")
else()
  set(PIPER_PHONEMIZE_RPATH_ORIGIN "@loader_path")
  set(PIPER_PHONEMIZE_RPATH_ORIGIN_PARENT "@loader_path/../lib")
endif()

if(UNIX)
  set(CMAKE_INSTALL_RPATH ${PIPER_PHONEMIZE_RPATH_ORIGIN})
  set(CMAKE_BUILD_RPATH "${PIPER_PHONEMIZE_RPATH_ORIGIN};${PIPER_PHONEMIZE_RPATH_ORIGIN_PARENT}")
endif()

if(NOT CMAKE_BUILD_TYPE)
  message(STATUS "No CMAKE_BUILD_TYPE given, default to Release")
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "")

option(BUILD_SHARED_LIBS "Whether to build shared libraries" ON)
option(BUILD_PIPER_PHONEMIZE_CORE_EXE "Whether to build piper_phonemize_exe" OFF)
option(BUILD_PIPER_PHONEMIZE_CORE_TESTS "Whether to build tests" OFF)
option(ENABLE_PIPER_PHONEMIZE_CORE_SONAME "Whether to enable soname" OFF)

message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
message(STATUS "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS}")
if(MSVC)
  message(STATUS "CMAKE_MSVC_RUNTIME_LIBRARY ${CMAKE_MSVC_RUNTIME_LIBRARY}")
endif()

if(BUILD_SHARED_LIBS)
  set(CMAKE_CXX_VISIBILITY_PRESET hidden)
  set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)
endif()

# Rust on Linux links static archives into PIE executables by default,
# so static objects need PIC as well.
if(NOT WIN32)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17 CACHE STRING "The C++ version to be used.")
endif()
set(CMAKE_CXX_EXTENSIONS OFF)
message(STATUS "C++ Standard version: ${CMAKE_CXX_STANDARD}")

if(MSVC)
  # Force compiler to use UTF-8 for IPA constants
  add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
  add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")
elseif(NOT APPLE)
  # Linux flags
  string(APPEND CMAKE_C_FLAGS " -Wall -Wextra -pthread")
  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -pthread -fexceptions")
endif()

# ---- espeak-ng (FetchContent, always built as static) ----

set(espeak_ng_URL  "https://github.com/csukuangfj/espeak-ng/archive/ed530aa113046142eb5115cf2fc9157854d0ffe1.zip")
set(espeak_ng_HASH "SHA256=e4e262cbe34f7fe21f91f1ba3397f2728e1f30eafbae7853f2b753a9ed13f0dd")

set(possible_file_locations
  $ENV{HOME}/Downloads/espeak-ng-ed530aa113046142eb5115cf2fc9157854d0ffe1.zip
  ${CMAKE_SOURCE_DIR}/espeak-ng-ed530aa113046142eb5115cf2fc9157854d0ffe1.zip
  ${CMAKE_BINARY_DIR}/espeak-ng-ed530aa113046142eb5115cf2fc9157854d0ffe1.zip
  /tmp/espeak-ng-ed530aa113046142eb5115cf2fc9157854d0ffe1.zip
)

foreach(f IN LISTS possible_file_locations)
  if(EXISTS ${f})
    set(espeak_ng_URL  "${f}")
    file(TO_CMAKE_PATH "${espeak_ng_URL}" espeak_ng_URL)
    message(STATUS "Found local downloaded espeak-ng: ${espeak_ng_URL}")
    break()
  endif()
endforeach()

include(FetchContent)

FetchContent_Declare(espeak_ng
  URL
    ${espeak_ng_URL}
  URL_HASH          ${espeak_ng_HASH}
)

FetchContent_GetProperties(espeak_ng)
if(NOT espeak_ng_POPULATED)
  message(STATUS "Downloading espeak-ng from ${espeak_ng_URL}")
  FetchContent_Populate(espeak_ng)
endif()
message(STATUS "espeak-ng is downloaded to ${espeak_ng_SOURCE_DIR}")
message(STATUS "espeak-ng binary dir is ${espeak_ng_BINARY_DIR}")

set(BUILD_ESPEAK_NG_TESTS OFF CACHE BOOL "" FORCE)
set(USE_ASYNC OFF CACHE BOOL "" FORCE)
set(USE_MBROLA OFF CACHE BOOL "" FORCE)
set(USE_LIBSONIC OFF CACHE BOOL "" FORCE)
set(USE_LIBPCAUDIO OFF CACHE BOOL "" FORCE)
set(BUILD_ESPEAK_NG_EXE OFF CACHE BOOL "" FORCE)
set(USE_KLATT OFF CACHE BOOL "" FORCE)
set(USE_SPEECHPLAYER OFF CACHE BOOL "" FORCE)
set(EXTRA_cmn ON CACHE BOOL "" FORCE)
set(EXTRA_ru ON CACHE BOOL "" FORCE)

if(BUILD_SHARED_LIBS)
  set(_build_shared_libs_bak ${BUILD_SHARED_LIBS})
  set(BUILD_SHARED_LIBS OFF)
endif()

add_subdirectory(${espeak_ng_SOURCE_DIR} ${espeak_ng_BINARY_DIR})

if(_build_shared_libs_bak)
  set_target_properties(espeak-ng
    PROPERTIES
      POSITION_INDEPENDENT_CODE ON
      C_VISIBILITY_PRESET hidden
      CXX_VISIBILITY_PRESET hidden
  )
  set(BUILD_SHARED_LIBS ON)
endif()

set(ESPEAK_NG_DIR ${espeak_ng_SOURCE_DIR})

if(WIN32 AND MSVC)
  target_compile_options(ucd PUBLIC
    /wd4309
  )

  target_compile_options(espeak-ng PUBLIC
    /wd4005
    /wd4018
    /wd4067
    /wd4068
    /wd4090
    /wd4101
    /wd4244
    /wd4267
    /wd4996
  )
endif()

if(UNIX AND NOT APPLE)
  target_compile_options(espeak-ng PRIVATE
    -Wno-unused-result
    -Wno-format-overflow
    -Wno-format-truncation
    -Wno-uninitialized
    -Wno-format
  )
endif()

target_include_directories(espeak-ng
  INTERFACE
    ${espeak_ng_SOURCE_DIR}/src/include
    ${espeak_ng_SOURCE_DIR}/src/ucd-tools/src/include
)

if(NOT BUILD_SHARED_LIBS)
  install(TARGETS
    espeak-ng
    ucd
  DESTINATION lib)
endif()

# ---- Declare library ----

add_library(
    piper_phonemize_core
    src/phonemize.cpp
    src/phoneme_ids.cpp
    src/shared.cpp
    src/c-api.cpp
)

target_compile_definitions(piper_phonemize_core
  PRIVATE
    PIPER_PHONEMIZE_BUILD_MAIN_LIB
)

if(BUILD_SHARED_LIBS)
  target_compile_definitions(piper_phonemize_core
    PUBLIC
      PIPER_PHONEMIZE_BUILD_SHARED_LIBS
  )
endif()

set_target_properties(
    piper_phonemize_core
  PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
)

if(ENABLE_PIPER_PHONEMIZE_CORE_SONAME)
  set_target_properties(piper_phonemize_core PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
  )
endif()

target_include_directories(
    piper_phonemize_core PUBLIC
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>"
    ${ESPEAK_NG_DIR}/src/include
    ${ESPEAK_NG_DIR}/src/ucd-tools/src/include
)

target_link_libraries(
    piper_phonemize_core
    espeak-ng
)

if(NOT BUILD_SHARED_LIBS)
  target_link_libraries(piper_phonemize_core ucd)
endif()

if(NOT BUILD_SHARED_LIBS AND APPLE)
  target_link_libraries(piper_phonemize_core "-framework Foundation")
endif()

if(NOT BUILD_SHARED_LIBS AND CMAKE_SYSTEM_NAME STREQUAL Linux)
  target_link_libraries(piper_phonemize_core -static-libstdc++ -static-libgcc)
endif()

if(ANDROID_NDK)
  target_link_libraries(piper_phonemize_core android log)
endif()

target_compile_features(piper_phonemize_core PUBLIC cxx_std_11)

if(BUILD_SHARED_LIBS)
  if(ANDROID OR (UNIX AND NOT APPLE))
    set_target_properties(piper_phonemize_core PROPERTIES
      LINK_FLAGS "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/src/piper-phonemize-symbols-c.lds"
    )
  elseif(APPLE)
    set_target_properties(piper_phonemize_core PROPERTIES
      LINK_FLAGS "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/src/piper-phonemize-symbols-c.exp"
    )
  endif()
endif()

# ---- CXX API library ----

add_library(
    piper_phonemize_cxx_api
    src/cxx-api.cc
)

target_compile_definitions(piper_phonemize_cxx_api
  PRIVATE
    PIPER_PHONEMIZE_BUILD_MAIN_LIB
)

target_link_libraries(piper_phonemize_cxx_api
    piper_phonemize_core
)

set_target_properties(
    piper_phonemize_cxx_api
  PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
)

if(ENABLE_PIPER_PHONEMIZE_CORE_SONAME)
  set_target_properties(piper_phonemize_cxx_api PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
  )
endif()

# ---- Declare install targets ----

include(GNUInstallDirs)

install(
    TARGETS piper_phonemize_core piper_phonemize_cxx_api
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(
    FILES
      ${CMAKE_SOURCE_DIR}/src/c-api.h
      ${CMAKE_SOURCE_DIR}/src/cxx-api.h
    DESTINATION include/piper-phonemize)

# ---- Tests ----

if(BUILD_PIPER_PHONEMIZE_CORE_TESTS)
  add_executable(test-c-api src/test-c-api.cpp)
  target_link_libraries(test-c-api piper_phonemize_core)

  add_executable(test-cxx-api src/test-cxx-api.cpp)
  target_link_libraries(test-cxx-api piper_phonemize_cxx_api)
endif()
