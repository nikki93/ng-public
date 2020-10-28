#!/bin/bash

set -e

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

  # Format
  format)
    clang-format -i -style=file src/*.h src/*.c
    ;;

  # Desktop
  release)
    case $PLATFORM in
      lin|macOS)
        nim cpp --compileOnly --nimcache:build/nim-gen-release -d:danger src/main.nim
        $CMAKE \
          -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-release) \
          -H. -Bbuild/release -GNinja
        $CMAKE --build build/release
        ./build/release/ng
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
    nim cpp --compileOnly --nimcache:build/nim-gen-web-release -d:danger -d:emscripten --cpu:wasm32 src/main.nim
    $CMAKE \
      -DWEB=ON \
      -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-web-release) \
      -H. -Bbuild/web-release -GNinja
    $CMAKE --build build/web-release
    ;;
  web-watch-release)
    find CMakeLists.txt src -type f | entr ./run.sh web-release
    ;;
  web-serve-release)
    npx http-server -c-1 build/web-release
    ;;
esac
