# SDL wrapper

type
  SdlWindow = object
  SdlWindowPtr* = ptr SdlWindow

  SdlRenderer = object
  SdlRendererPtr* = ptr SdlRenderer

  SdlEventType* {.size: sizeof(uint32).} = enum
    QuitEvent = 0x100

  SdlEvent* = object
    kind*: SdlEventType
    padding: array[56-sizeof(SdlEventType), byte]

const
  INIT_VIDEO* = 0x00000020

proc init*(flags: uint32): cint
  {.importc: "SDL_Init".}

proc quit*()
  {.importc: "SDL_Quit".}

proc createWindowAndRenderer*(
  width, height: cint,
  window_flags: cuint,
  window: var SdlWindowPtr, renderer: var SdlRendererPtr): cint
  {.importc: "SDL_CreateWindowAndRenderer".}

proc destroy*(window: SdlWindowPtr)
  {.importc: "SDL_DestroyWindow".}

proc destroy*(renderer: SdlRendererPtr)
  {.importc: "SDL_DestroyRenderer".}

proc pollEvent*(event: var SdlEvent): bool
  {.importc: "SDL_PollEvent".}

proc setDrawColor*(
  renderer: SdlRendererPtr, r, g, b: uint8, a: uint8 = 0xff): cint
  {.importc: "SDL_SetRenderDrawColor", discardable.}

proc clear*(renderer: SdlRendererPtr): cint
  {.importc: "SDL_RenderClear", discardable.}

proc present*(renderer: SdlRendererPtr) {.importc: "SDL_RenderPresent".}


# Emscripten wrapper

proc emscripten_set_main_loop*(
  x: proc() {.cdecl.}, fps: int, simulateInfiniteLoop: bool) {.importc.}


# main

echo "hello from nim-c!"

if init(INIT_VIDEO) == -1:
  quit("couldn't initialize sdl")

var window: SdlWindowPtr
var renderer: SdlRendererPtr
if createWindowAndRenderer(800, 600, 0, window, renderer) == -1:
  quit("couldn't create window and renderer")

var shouldQuit = false

proc frame() {.cdecl.} =
  var evt: SdlEvent
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      shouldQuit = true
  renderer.setDrawColor(0xcc, 0xe4, 0xf5)
  renderer.clear()
  renderer.present()

when defined(emscripten):
  emscripten_set_main_loop(frame, 0, true)
else:
  while not shouldQuit:
    frame()

renderer.destroy()
window.destroy()
