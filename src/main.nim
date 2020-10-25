# SDL wrapper

type
  SdlWindow = object
  SdlWindowPtr* = ptr SdlWindow
  SdlRenderer = object
  SdlRendererPtr* = ptr SdlRenderer

proc init*(flags: uint32): cint {.importc: "SDL_Init".}

proc quit*() {.importc: "SDL_Quit".}

proc createWindowAndRenderer*(
  width, height: cint,
  window_flags: cuint,
  window: var SdlWindowPtr, renderer: var SdlRendererPtr): cint {.
    importc: "SDL_CreateWindowAndRenderer".}

proc destroy*(window: SdlWindowPtr) {.importc: "SDL_DestroyWindow".}

proc destroy*(renderer: SdlRendererPtr) {.importc: "SDL_DestroyRenderer".}

proc pollEvent*(event: pointer): cint {.importc: "SDL_PollEvent".}

proc setDrawColor*(renderer: SdlRendererPtr, r, g, b, a: uint8): cint {.
  importc: "SDL_SetRenderDrawColor", discardable.}

proc present*(renderer: SdlRendererPtr) {.importc: "SDL_RenderPresent".}

proc clear*(renderer: SdlRendererPtr): cint {.
  importc: "SDL_RenderClear", discardable.}

proc drawLines*(
  renderer: SdlRendererPtr, points: ptr tuple[x, y: cint], count: cint): cint {.
    importc: "SDL_RenderDrawLines", discardable.}

proc emscripten_set_main_loop*(
  x: proc() {.cdecl.}, fps: int, simulateInfiniteLoop: bool) {.importc.}


# main

echo "hello from nim!"

const INIT_VIDEO* = 0x00000020

if init(INIT_VIDEO) == -1:
  quit("couldn't initialize sdl")

var window: SdlWindowPtr
var renderer: SdlRendererPtr
if createWindowAndRenderer(800, 600, 0, window, renderer) == -1:
  quit("couldn't create window and renderer")

proc frame() {.cdecl.} =
  discard pollEvent(nil)
  renderer.setDrawColor(0xff, 0, 0, 0xff)
  renderer.clear()
  renderer.present()

when defined(emscripten):
  emscripten_set_main_loop(frame, 0, true)
else:
  while true:
    frame()
