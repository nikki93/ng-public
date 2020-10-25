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

nim_c_srcs() { # Parse Nim's json output to get list of C sources
  cat $1/main.json | sed -e 's/[",]//g' -e 's/\.o$//g' -n -e '/\.c$/p' | tr '\n' ';'
}

case "$1" in
  # DB
  db)
    $CMAKE -DNIM_C_SRCS=$(nim_c_srcs build/nim-c-release) --DCMAKE_EXPORT_COMPILE_COMMANDS=ON -H. -Bbuild/db -GNinja
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
        nim c --compileOnly --nimcache:build/nim-c-release -d:danger src/main.nim
        $CMAKE \
          -DNIM_C_SRCS=$(nim_c_srcs build/nim-c-release) \
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
    nim c --compileOnly --nimcache:build/nim-c-web-release -d:danger -d:emscripten --cpu:wasm32 src/main.nim
    nim js --compileOnly --out:build/nim-js-web-release/nim_index.js -d:danger web/index.nim
    $CMAKE \
      -DNIM_C_SRCS=$(nim_c_srcs build/nim-c-web-release) \
      -DNIM_JS_INDEX=build/nim-js-web-release/nim_index.js \
      -DWEB=ON \
      -H. -Bbuild/web-release -GNinja
    $CMAKE --build build/web-release
    ;;
  web-watch-release)
    find CMakeLists.txt src web -type f | entr ./run.sh web-release
    ;;
  web-serve-release)
    npx http-server -c-1 build/web-release
    ;;
esac
