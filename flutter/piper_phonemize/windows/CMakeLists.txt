# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "piper_phonemize")
project(${PROJECT_NAME} LANGUAGES CXX)

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
  set(LIB_ARCH_DIR "x64")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
  set(LIB_ARCH_DIR "arm64")
else()
  message(FATAL_ERROR "Unsupported arch: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

# List of absolute paths to libraries that should be bundled with the plugin.
set(piper_phonemize_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/${LIB_ARCH_DIR}/piper_phonemize_core.dll"
  PARENT_SCOPE
)
