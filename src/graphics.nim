const sdlH = "\"precomp.h\""

const gpuH = "\"precomp.h\""

type
  SDLWindow {.importc: "SDL_Window", header: sdlH.} = object

  GPUTarget {.importc: "GPU_Target", header: gpuH.} = object

  State = object
    r, g, b, a: uint8
    viewX, viewY: float
    viewWidth, viewHeight: float

  Graphics* = object
    window: ptr SDLWindow
    screen: ptr GPUTarget
    dpiScale: float
    state: State


# State

proc setState(gfx: var Graphics, state: State) =
  discard


# Coordinates

proc selectWindowSize(gfx: var Graphics): (int, int) =
  var bestW = 800
  # TODO(nikki): Use canvas width in Emscripten (see C++ code)
  (bestW, (bestW.toFloat * gfx.state.viewHeight / gfx.state.viewWidth).toInt)


# Init / deinit

const SDL_INIT_VIDEO = 0x00000020

proc initGraphics*(title: string, viewWidth, viewHeight: float): Graphics =
  # Initial state
  result.state = State(
    r: 0xff, g: 0xff, b: 0xff, a: 0xff,
    viewX: 400, viewY: 255,
    viewWidth: viewWidth, viewHeight: viewHeight)

  # Init SDL video
  proc SDL_InitSubSystem(flags: uint32): int
    {.importc, header: sdlH.}
  discard SDL_InitSubSystem(SDL_INIT_VIDEO)

  # Emscripten particulars
  when defined(emscripten):
    proc SDL_SetHint(nane: cstring, value: cstring): bool
      {.importc, header: sdlH.}
    discard SDL_SetHint("SDL_EMSCRIPTEN_KEYBOARD_ELEMENT", "#canvas")

  # Create window
  let (bestW, bestH) = result.selectWindowSize()
  proc SDL_CreateWindow(title: cstring, x, y, w, h: int,
      flags: uint32): ptr SDLWindow
    {.importc, header: sdlH.}
  const SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000
  const SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000
  const SDL_WINDOW_OPENGL = 0x00000002
  result.window = SDL_CreateWindow(title,
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      bestW, bestH,
      SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_OPENGL)

  # Create renderer
  proc SDL_GetWindowID(window: ptr SDLWindow): uint32
    {.importc, header: sdlH.}
  proc GPU_SetInitWindow(windowId: uint32)
    {.importc, header: gpuH.}
  GPU_SetInitWindow(SDL_GetWindowID(result.window))
  var w, h: cint
  proc SDL_GetWindowSize(window: ptr SDLWindow, w, h: var cint)
    {.importc, header: sdLH.}
  SDL_GetWindowSize(result.window, w, h)
  proc GPU_Init(w, h: uint16, flags: uint32): ptr GPUTarget
    {.importc, header: gpuH.}
  const GPU_DEFAULT_INIT_FLAGS = 0
  result.screen = GPU_Init(cast[uint16](w), cast[uint16](h),
    GPU_DEFAULT_INIT_FLAGS)
  proc GPU_SetWindowResolution(w, h: uint16)
    {.importc, header: gpuH.}
  GPU_SetWindowResolution(cast[uint16](w), cast[uint16](h))

  # Apply initial state
  result.setState(result.state)

  echo "initialized graphics"

proc `=destroy`(gfx: var Graphics) =
  # Destroy renderer
  if gfx.screen != nil:
    proc GPU_Quit()
      {.importc, header: gpuH.}
    GPU_Quit()

  # Destroy window and deinit SDL video
  if gfx.window != nil:
    proc SDL_DestroyWindow(window: ptr SDLWindow)
      {.importc, header: sdlH.}
    proc SDL_QuitSubSystem(flags: uint32)
      {.importc, header: sdlH.}
    SDL_DestroyWindow(gfx.window)
    SDL_QuitSubSystem(SDL_INIT_VIDEO)

  echo "deinitialized graphics"


# Draw

proc clear*(gfx: var Graphics, r, g, b: uint8) =
  proc GPU_ClearRGB(target: ptr GPUTarget, r, g, b: uint8)
    {.importc, header: gpuH.}
  GPU_ClearRGB(gfx.screen, r, g, b)


# Frame

proc beginFrame(gfx: var Graphics) =
  gfx.clear(0xff, 0xff, 0xff)

proc endFrame(gfx: var Graphics) =
  proc GPU_Flip(target: ptr GPUTarget)
    {.importc, header: gpuH.}
  GPU_Flip(gfx.screen)

template frame*(gfx: var Graphics, body: untyped) =
  beginFrame(gfx)
  body
  endFrame(gfx)
