include_directories(${PROJECT_SOURCE_DIR}/src)  # for c-api.h

if(NOT DEFINED ANDROID_ABI)
  if(NOT DEFINED ENV{JAVA_HOME})
    message(FATAL_ERROR "Please set the environment variable JAVA_HOME")
  endif()
  include_directories($ENV{JAVA_HOME}/include)
  include_directories($ENV{JAVA_HOME}/include/linux)
  include_directories($ENV{JAVA_HOME}/include/darwin)
  include_directories($ENV{JAVA_HOME}/include/win32)
endif()

set(sources
  jni.cc
)

add_library(piper-phonemize-jni SHARED ${sources})

target_compile_definitions(piper-phonemize-jni PRIVATE PIPER_PHONEMIZE_BUILD_SHARED_LIBS=1)
target_compile_definitions(piper-phonemize-jni PRIVATE PIPER_PHONEMIZE_BUILD_MAIN_LIB=1)

if(ANDROID OR (UNIX AND NOT APPLE))
  set_target_properties(piper-phonemize-jni PROPERTIES
    LINK_FLAGS "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/piper-phonemize-symbols.lds"
  )
elseif(APPLE)
  set_target_properties(piper-phonemize-jni PROPERTIES
    LINK_FLAGS "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/piper-phonemize-symbols.exp"
  )
endif()

target_link_libraries(piper-phonemize-jni piper_phonemize_core)
install(TARGETS piper-phonemize-jni DESTINATION lib)
