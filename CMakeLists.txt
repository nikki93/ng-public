cmake_minimum_required(VERSION 3.16)


#
# Toolchain
#

if(WEB)
  # Emscripten
  set(CMAKE_TOOLCHAIN_FILE ../emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake)
elseif(WIN32)
  set(CMAKE_C_COMPILER "C:/Program Files/LLVM/bin/clang.exe")
  set(CMAKE_CXX_COMPILER "C:/Program Files/LLVM/bin/clang++.exe")
elseif(APPLE AND (NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "iOS"))
  # Homebrew LLVM for compatibility with Homebrew 'clang-tidy'
  set(CMAKE_C_COMPILER /usr/local/opt/llvm/bin/clang)
  set(CMAKE_CXX_COMPILER /usr/local/opt/llvm/bin/clang++)
else()
  set(CMAKE_C_COMPILER clang)
  set(CMAKE_CXX_COMPILER clang++)
endif()


#
# Project
#

project(ng)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release) # Release build by default
endif()


#
# Target
#

if(LIB)
  add_library(ng STATIC)
else()
  add_executable(ng)
endif()

# Sources
file(GLOB MY_SOURCES CONFIGURE_DEPENDS src/*.h src/*.c ${NIM_C_DIR}/*.c)
if("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
  list(APPEND MY_SOURCES "src/platform.mm")
endif()
if(LIB)
  list(REMOVE_ITEM MY_SOURCES "${CMAKE_SOURCE_DIR}/src/main.c")
endif()
target_sources(ng PRIVATE ${MY_SOURCES})

# Standard
target_compile_features(ng PRIVATE cxx_std_17)
set_target_properties(ng PROPERTIES CXX_EXTENSIONS OFF)

# Warnings
if(MSVC)
  target_compile_options(ng PRIVATE /W4 /WX
    #/wd4100 # Disable 'unreferenced formal parameter'
    /wd4244 # Disable 'possible loss of data'
    /wd4307 # Disable 'integral constant overflow'
    /wd4702 # Disable 'unreachable code'
    /wd4456 # Disable 'declaration hides previous local declaration'
    /wd4005 # Disable 'macro redefinition'
    /wd4505 # Disable 'unreferenced local function has been removed'
    )
  target_link_options(ng PRIVATE /WX)
else()
  target_compile_options(ng PRIVATE -fcolor-diagnostics -pedantic-errors -Wall -Wextra -Wno-missing-braces -Wno-gnu-zero-variadic-macro-arguments
    -Wno-unused-parameter -Wno-unused-label)
  target_link_options(ng PRIVATE -fcolor-diagnostics -pedantic-errors -Wall -Wextra -Wno-missing-braces)
  if(WIN32)
    target_compile_options(ng PRIVATE -Wno-language-extension-token)
    target_link_options(ng PRIVATE -Wno-language-extension-token)
  endif()
endif()

# Precompiled header
if(NOT CMAKE_EXPORT_COMPILE_COMMANDS)
  target_precompile_headers(ng PRIVATE src/precomp.h)
endif()

# Web flags
if(WEB)
  target_link_options(ng PRIVATE "SHELL:--bind")
  target_link_options(ng PRIVATE "SHELL:-s WASM=1")
  target_link_options(ng PRIVATE "SHELL:-s MAX_WEBGL_VERSION=2")
  target_link_options(ng PRIVATE "SHELL:-s TOTAL_MEMORY=256MB")
  if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    target_compile_options(ng PRIVATE "SHELL:-g4 --source-map-base file://${CMAKE_BINARY_DIR}/ -fsanitize=leak")
    target_link_options(ng PRIVATE "SHELL:-g4 --source-map-base file://${CMAKE_BINARY_DIR}/ -fsanitize=leak")
  else()
    target_compile_options(ng PRIVATE "SHELL:--profiling")
    target_link_options(ng PRIVATE "SHELL:--profiling")
  endif()
endif()

# iOS extras
if("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
  set_target_properties(ng PROPERTIES
    BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST etc/info_ios.plist
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
endif()


#
# Dependencies
#

# Nim
if(WIN32)
  # TODO(nikki): Windows Nim include paths...
else()
  target_include_directories(ng PRIVATE ~/.choosenim/toolchains/nim-1.4.0/lib)
endif()

# SDL2
#if(WEB)
#  target_compile_options(ng PRIVATE "SHELL:-s USE_SDL=2")
#  target_link_options(ng PRIVATE "SHELL:-s USE_SDL=2")
#elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
#  target_include_directories(ng PRIVATE vendor/SDL2/include)
#  target_link_libraries(ng PRIVATE
#    "-L${PROJECT_SOURCE_DIR}/vendor/prebuilt-ios" SDL2
#    "-framework AVFoundation" "-framework AudioToolbox" "-framework CoreBluetooth" "-framework CoreGraphics" "-framework CoreMotion"
#    "-framework Foundation" "-framework GameController" "-framework Metal" "-framework OpenGLES" "-framework QuartzCore" "-framework UIKit")
#else()
#  set(SDL_STATIC ON CACHE BOOL "" FORCE)
#  set(SDL_SHARED OFF CACHE BOOL "" FORCE)
#  add_subdirectory(vendor/SDL2 EXCLUDE_FROM_ALL)
#  target_link_libraries(ng PRIVATE SDL2-static)
#endif()

# sdl-gpu
#target_include_directories(ng PRIVATE vendor/sdl-gpu/include)
#add_library(my_SDL_gpu STATIC)
#target_include_directories(my_SDL_gpu PRIVATE vendor/sdl-gpu/include vendor/SDL2/include)
#file(GLOB SDL_GPU_SOURCES CONFIGURE_DEPENDS vendor/sdl-gpu/src/*.c)
#target_sources(my_SDL_gpu PRIVATE ${SDL_GPU_SOURCES})
#target_sources(my_SDL_gpu PRIVATE
#  vendor/sdl-gpu/src/externals/stb_image/stb_image.c vendor/sdl-gpu/src/externals/stb_image_write/stb_image_write.c)
#target_include_directories(my_SDL_gpu PRIVATE
#  vendor/sdl-gpu/src/externals/stb_image vendor/sdl-gpu/src/externals/stb_image_write)
#if(WEB)
#  target_compile_options(my_SDL_gpu PRIVATE "SHELL:-s USE_SDL=2")
#  target_link_options(my_SDL_gpu PRIVATE "SHELL:-s USE_SDL=2")
#  target_compile_definitions(my_SDL_gpu PRIVATE -DSDL_GPU_DISABLE_OPENGL -DSDL_GPU_DISABLE_GLES_1 -DSDL_GPU_DISABLE_GLES_3)
#elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
#  target_compile_definitions(my_SDL_gpu PRIVATE -DSDL_GPU_DISABLE_OPENGL)
#else()
#  find_package(OpenGL REQUIRED)
#  if(APPLE)
#    target_link_libraries(my_SDL_gpu PRIVATE ${OPENGL_gl_LIBRARY})
#  else()
#    target_link_libraries(my_SDL_gpu PRIVATE ${OPENGL_LIBRARIES})
#  endif()
#  target_link_libraries(my_SDL_gpu PRIVATE SDL2-static)
#  target_sources(my_SDL_gpu PRIVATE vendor/sdl-gpu/src/externals/glew/glew.c)
#  target_include_directories(my_SDL_gpu PRIVATE vendor/sdl-gpu/src/externals/glew vendor/sdl-gpu/src/externals/glew/GL)
#  target_compile_definitions(my_SDL_gpu PRIVATE -DGLEW_STATIC)
#  target_compile_definitions(my_SDL_gpu PRIVATE -DSDL_GPU_DISABLE_GLES)
#endif()
#target_link_libraries(ng PRIVATE my_SDL_gpu)

# stb
#target_include_directories(ng PRIVATE vendor/stb)

# entt
#target_include_directories(ng PRIVATE vendor/entt/src)

# Chipmunk2D
#set(BUILD_DEMOS OFF CACHE BOOL "" FORCE)
#set(INSTALL_DEMOS OFF CACHE BOOL "" FORCE)
#set(BUILD_SHARED OFF CACHE BOOL "" FORCE)
#set(BUILD_STATIC ON CACHE BOOL "" FORCE)
#set(INSTALL_STATIC OFF CACHE BOOL "" FORCE)
#add_subdirectory(vendor/Chipmunk2D EXCLUDE_FROM_ALL)
#target_include_directories(ng PRIVATE vendor/Chipmunk2D/include)
#target_link_libraries(ng PRIVATE chipmunk_static)

# rapidjson
#target_include_directories(ng PRIVATE vendor/rapidjson/include)


#
# Assets
#

# Bundle 'assets/'
if(WEB)
  target_link_options(ng PRIVATE "SHELL:--preload-file ${PROJECT_SOURCE_DIR}/assets@assets")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
  target_sources(ng PRIVATE "assets")
  set_target_properties(ng PROPERTIES RESOURCE "assets")
endif()

# Static web files
if(WEB)
  configure_file(web/index.html index.html COPYONLY)
  configure_file(web/index.css index.css COPYONLY)
endif()

# iOS launch screen
if("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
  target_sources(ng PRIVATE "etc/launch.storyboard")
endif()
