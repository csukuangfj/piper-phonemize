# See also https://github.com/cmake-js/cmake-js
# npm install cmake-js
# ./node_modules/.bin/cmake-js --help
# ./node_modules/.bin/cmake-js --version
# ./node_modules/.bin/cmake-js compile --help
# ./node_modules/.bin/cmake-js compile --log-level
# ./node_modules/.bin/cmake-js compile --log-level verbose
cmake_minimum_required(VERSION 3.15)
cmake_policy(SET CMP0091 NEW)
cmake_policy(SET CMP0042 NEW)

project(piper-phonemize)

set(CMAKE_CXX_STANDARD 17)

if(NOT WIN32)
  set(CMAKE_SKIP_BUILD_RPATH FALSE)
  set(BUILD_RPATH_USE_ORIGIN TRUE)
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()

if(NOT APPLE)
  set(PIPER_PHONEMIZE_RPATH_ORIGIN "$ORIGIN")
else()
  set(PIPER_PHONEMIZE_RPATH_ORIGIN "@loader_path")
endif()

if(NOT WIN32)
  set(CMAKE_INSTALL_RPATH ${PIPER_PHONEMIZE_RPATH_ORIGIN})
  set(CMAKE_BUILD_RPATH ${PIPER_PHONEMIZE_RPATH_ORIGIN})
endif()

# Include Node.js headers from cmake-js
include_directories(${CMAKE_JS_INC})

set(srcs
  src/piper-phonemize-addon.cc
  src/phonemize.cc
)

if(NOT DEFINED ENV{PIPER_PHONEMIZE_INSTALL_DIR})
  message(FATAL_ERROR "
Please run:
  cd /path/to/piper-phonemize
  mkdir -p build
  cd build
  cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=./install ..
  make install
  export PIPER_PHONEMIZE_INSTALL_DIR=$PWD/install
  ")
endif()

include_directories($ENV{PIPER_PHONEMIZE_INSTALL_DIR}/include/piper-phonemize)

# See https://nodejs.github.io/node-addon-examples/build-tools/cmake-js
# Include Node-API wrappers
execute_process(
  COMMAND node -p "require('node-addon-api').include"
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE NODE_ADDON_API_DIR
)

string(REPLACE "\n" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
string(REPLACE "\"" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
include_directories(${NODE_ADDON_API_DIR})

link_directories($ENV{PIPER_PHONEMIZE_INSTALL_DIR}/lib)

add_library(${PROJECT_NAME} SHARED ${srcs} ${CMAKE_JS_SRC})
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "" SUFFIX ".node")
target_link_libraries(${PROJECT_NAME} ${CMAKE_JS_LIB})

target_link_libraries(${PROJECT_NAME}
  piper_phonemize_core
  -Wl,-rpath,$ENV{PIPER_PHONEMIZE_INSTALL_DIR}/lib
  -Wl,-rpath,${PIPER_PHONEMIZE_RPATH_ORIGIN}
)

if(MSVC AND CMAKE_JS_NODELIB_DEF AND CMAKE_JS_NODELIB_TARGET)
  # Generate node.lib
  execute_process(COMMAND ${CMAKE_AR} /def:${CMAKE_JS_NODELIB_DEF} /out:${CMAKE_JS_NODELIB_TARGET} ${CMAKE_STATIC_LINKER_FLAGS})
endif()
