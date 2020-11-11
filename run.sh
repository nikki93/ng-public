#!/bin/bash

set -e

PLATFORM="macOS"
CMAKE="cmake"
TIME="time"
TIME_TOTAL="time"
NIM="nim"
NIM_CC="clang"

if [[ -f /proc/version ]]; then
  if grep -q Linux /proc/version; then
    PLATFORM="lin"
    TIME="time --format=%es\n"
    TIME_TOTAL="time --format=total\t%es\n"
  fi
  if grep -q Microsoft /proc/version; then
    PLATFORM="win"
    CMAKE="cmake.exe"
    NIM="nim.exe"
    NIM_CC="vcc"
  fi
fi

nim_gen_srcs() { # Parse Nim's JSON output to get list of C/C++ sources
  cat $1/main.json | sed -e 's/[",]//g' -e 's/\.o[bj]*$//g' -n -e '/\.cp*$/p' | tr '\n' ';'
}

case "$1" in
  # DB
  db)
    $CMAKE -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-release) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -H. -Bbuild/db -GNinja
    cp ./build/db/compile_commands.json .
    ;;

  # Desktop
  release)
    $TIME $NIM cpp \
      --verbosity:0 \
      --compileOnly \
      --cc:$NIM_CC \
      --nimcache:build/nim-gen-release \
      -d:danger \
      ${TESTS:+-d:runTests} \
      ${VALGRIND:+-d:useMalloc} \
      src/main.nim
    case $PLATFORM in
      lin|macOS)
        $TIME $CMAKE \
          -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-release) \
          -H. -Bbuild/release -GNinja
        $TIME $CMAKE --build build/release
        if [[ -z "$VALGRIND" ]]; then
          ./build/release/ng
        else
          SUPPRESSIONS="
          {
            ignore_versioned_system_libs
            Memcheck:Leak
            ...
            obj:*/lib*/lib*.so.*
          }
          {
            ignore_iris_dri
            Memcheck:Addr1
            ...
            obj:*/dri/iris_dri.so
          }
          {
            ignore_iris_dri
            Memcheck:Addr2
            ...
            obj:*/dri/iris_dri.so
          }
          {
            ignore_iris_dri
            Memcheck:Addr4
            ...
            obj:*/dri/iris_dri.so
          }
          {
            ignore_iris_dri
            Memcheck:Addr8
            ...
            obj:*/dri/iris_dri.so
          }
          "
          valgrind \
            --suppressions=<(echo "$SUPPRESSIONS") \
            --gen-suppressions=all \
            --leak-check=full \
            -s \
            ./build/release/ng
        fi
        ;;
      win)
        $TIME $CMAKE \
          -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-release) \
          -H. -Bbuild/msvc -G"Visual Studio 16"
        $TIME $CMAKE --build build/msvc --config Release
        ./build/msvc/Release/ng.exe 
        ;;
    esac
    ;;

  # Web
  web-release)
    $TIME $NIM cpp \
      --verbosity:0 \
      --compileOnly \
      --nimcache:build/nim-gen-web-release \
      -d:danger \
      -d:emscripten \
      --cpu:wasm32 \
      --os:Linux \
      ${TESTS:+-d:runTests} \
      src/main.nim
    $TIME $CMAKE \
      -DWEB=ON \
      -DNIM_GEN_SRCS=$(nim_gen_srcs build/nim-gen-web-release) \
      -H. -Bbuild/web-release -GNinja
    $TIME $CMAKE --build build/web-release
    ;;
  web-watch-release)
    find CMakeLists.txt src assets -type f | entr $TIME_TOTAL ./run.sh web-release
    ;;
  web-serve-release)
    npx http-server -c-1 build/web-release
    ;;
  web-publish)
    ./run.sh web-release
    rsync -avP build/web-release/{index.*,ng.*} dh_bedxci@dreamhotel.xyz:dreamhotel.xyz/ng
    ;;
esac
