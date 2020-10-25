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

case "$1" in
  # DB
  db)
    $CMAKE -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/db -GNinja
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
        $CMAKE -DNIM_C_DIR=build/nim-c-release -H. -Bbuild/release -GNinja
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
#  debug)
#    case $PLATFORM in
#      lin|macOS)
#        $CMAKE -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/debug -GNinja
#        $CMAKE --build build/debug
#        ./build/debug/ng
#        ;;
#      win)
#        $CMAKE -H. -Bbuild/msvc -G"Visual Studio 16"
#        $CMAKE --build build/msvc --config Debug
#        ./build/msvc/Debug/ng.exe 
#        ;;
#    esac
#    ;;

  # Mobile
#  ios-debug)
#    $CMAKE -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=6PUB3623F7 -H. -Bbuild/ios -GXcode
#    cmake --build build/ios --config Debug
#    ios-deploy --no-wifi --debug --bundle build/ios/Debug-iphoneos/ng.app
#    ;;
#  ios-release)
#    $CMAKE -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=6PUB3623F7 -H. -Bbuild/ios -GXcode
#    cmake --build build/ios --config Release
#    ios-deploy --no-wifi --justlaunch --bundle build/ios/Release-iphoneos/ng.app
#    ;;

  # Web
  web-release)
    nim c --compileOnly --nimcache:build/nim-c-web-release -d:danger -d:emscripten --cpu:wasm32 src/main.nim
    $CMAKE -DNIM_C_DIR=build/nim-c-web-release -DWEB=ON -H. -Bbuild/web-release -GNinja
    $CMAKE --build build/web-release
    ;;
#  web-debug)
#    $CMAKE -DCMAKE_BUILD_TYPE=Debug -DWEB=ON -H. -Bbuild/web-debug -GNinja
#    $CMAKE --build build/web-debug
#    ;;
  web-watch-release)
    find CMakeLists.txt src web -type f | entr ./run.sh web-release
    ;;
#  web-watch-debug)
#    find CMakeLists.txt src web -type f | entr ./run.sh web-debug
#    ;;
  web-serve-release)
    npx http-server -c-1 build/web-release
    ;;
#  web-serve-debug)
#    npx http-server -c-1 build/web-debug
#    ;;
#  web-publish)
#    ./run.sh web-release
#    rsync -avP build/web-release/{index.*,ng.*} # TODO(nikki): add host here...
#    ;;
esac
