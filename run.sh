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
    clang-format -i -style=file src/engine/* src/game/* src/main.cc
    ;;

  # Desktop
  release)
    case $PLATFORM in
      lin|macOS)
        $CMAKE -H. -Bbuild/release -GNinja
        $CMAKE --build build/release
        ./build/release/ng
        ;;
      win)
        $CMAKE -H. -Bbuild/msvc -G"Visual Studio 16"
        $CMAKE --build build/msvc --config Release
        ./build/msvc/Release/ng.exe 
        ;;
    esac
    ;;
  debug)
    case $PLATFORM in
      lin|macOS)
        $CMAKE -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/debug -GNinja
        $CMAKE --build build/debug
        ./build/debug/ng
        ;;
      win)
        $CMAKE -H. -Bbuild/msvc -G"Visual Studio 16"
        $CMAKE --build build/msvc --config Debug
        ./build/msvc/Debug/ng.exe 
        ;;
    esac
    ;;
  lib-release)
    case $PLATFORM in
      lin|macOS)
        $CMAKE -DLIB=ON -H. -Bbuild/lib-release -GNinja
        $CMAKE --build build/lib-release
        ;;
      win)
        $CMAKE -DLIB=ON -H. -Bbuild/lib-msvc -G"Visual Studio 16"
        $CMAKE --build build/lib-msvc --config Release
        ;;
    esac
    ;;

  # Mobile
  ios-debug)
    $CMAKE -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=6PUB3623F7 -H. -Bbuild/ios -GXcode
    cmake --build build/ios --config Debug
    ios-deploy --no-wifi --debug --bundle build/ios/Debug-iphoneos/ng.app
    ;;
  ios-release)
    $CMAKE -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=6PUB3623F7 -H. -Bbuild/ios -GXcode
    cmake --build build/ios --config Release
    ios-deploy --no-wifi --justlaunch --bundle build/ios/Release-iphoneos/ng.app
    ;;

  # Web
  web-release)
    $CMAKE -DWEB=ON -H. -Bbuild/web-release -GNinja
    $CMAKE --build build/web-release
    ;;
  web-debug)
    $CMAKE -DCMAKE_BUILD_TYPE=Debug -DWEB=ON -H. -Bbuild/web-debug -GNinja
    $CMAKE --build build/web-debug
    ;;
  web-lib-release)
    $CMAKE -DLIB=ON -DWEB=ON -H. -Bbuild/web-lib-release -GNinja
    $CMAKE --build build/web-lib-release
    ;;
  web-watch-release)
    find CMakeLists.txt src web -type f | entr ./run.sh web-release
    ;;
  web-watch-debug)
    find CMakeLists.txt src web -type f | entr ./run.sh web-debug
    ;;
  web-serve-release)
    npx http-server -c-1 build/web-release
    ;;
  web-serve-debug)
    npx http-server -c-1 build/web-debug
    ;;
  web-publish)
    ./run.sh web-release
    rsync -avP build/web-release/{index.*,ng.*} # TODO(nikki): add host here...
    ;;
esac
