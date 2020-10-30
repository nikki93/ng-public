#!/bin/bash

set -e
TIME="time --format=%es\n"

PLATFORM="macOS"
CMAKE="cmake"

if [[ -f /proc/version ]]; then
  if grep -q Linux /proc/version; then
    PLATFORM="lin"
  fi
  if grep -q Microsoft /proc/version; then
    PLATFORM="win"
    CMAKE="cmake.exe"
  fi
fi

nim_gen_srcs() { # Parse Nim's JSON output to get list of C/C++ sources
  cat $1/main.json | sed -e 's/[",]//g' -e 's/\.o$//g' -n -e '/\.cp*$/p' | tr '\n' ';'
}

case "$1" in
  # DB
  db)
    $CMAKE -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-release) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -H. -Bbuild/db -GNinja
    cp ./build/db/compile_commands.json .
    ;;

  # Desktop
  release)
    case $PLATFORM in
      lin|macOS)
        $TIME nim cpp \
          --compileOnly \
          --nimcache:build/nim-gen-release \
          -d:danger \
          ${TESTS:+-d:runTests} \
          ${VALGRIND:+-d:useMalloc} \
          src/main.nim
        $TIME $CMAKE \
          -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-release) \
          -H. -Bbuild/release -GNinja
        $TIME $CMAKE --build build/release
        if [[ -z "$VALGRIND" ]]; then
          ./build/release/ng
        else
          valgrind \
            --suppressions=<(echo -e '{\n ignore_versioned_libs\n Memcheck:Leak\n ...\n obj:*/lib*/lib*.so.*\n }\n') \
            --leak-check=full \
            -s \
            ./build/release/ng
        fi
        ;;
#      win)
#        $CMAKE -H. -Bbuild/msvc -G"Visual Studio 16"
#        $CMAKE --build build/msvc --config Release
#        ./build/msvc/Release/ng.exe 
#        ;;
    esac
    ;;

  # Web
  web-release)
    $TIME nim cpp \
      --compileOnly \
      --nimcache:build/nim-gen-web-release \
      -d:danger \
      -d:emscripten \
      --cpu:wasm32 \
      ${TESTS:+-d:runTests} \
      src/main.nim
    $TIME $CMAKE \
      -DWEB=ON \
      -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-web-release) \
      -H. -Bbuild/web-release -GNinja
    $TIME $CMAKE --build build/web-release
    ;;
  web-watch-release)
    find CMakeLists.txt src -type f | entr ./run.sh web-release
    ;;
  web-serve-release)
    npx http-server -c-1 build/web-release
    ;;
esac
