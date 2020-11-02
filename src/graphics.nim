const sdlH = "\"precomp.h\""


type
  SDLWindow {.importc: "SDL_Window", header: sdlH.} = object

  State = object
    r, g, b, a: uint8
    viewX, viewY: float
    viewWidth, viewHeight: float

  Graphics* = object
    window: ptr SDLWindow
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


# Graphics instance

const SDL_INIT_VIDEO = 0x00000020

proc initGraphics*(title: string, viewWidth, viewHeight: float): Graphics =
  # Initial state
  result.state = State(
    r: 0xff, g: 0xff, b: 0xff, a: 0xff,
    viewX: 400, viewY: 255,
    viewWidth: viewWidth, viewHeight: viewHeight)

  # SDL init
  proc SDL_InitSubSystem(flags: uint32): int
    {.importc, header: sdlH.}
  discard SDL_InitSubSystem(SDL_INIT_VIDEO)

  # Emscripten particulars
  when defined(emscripten):
    proc SDL_SetHint(nane: cstring, value: cstring): cint
      {.importc, header: sdlH.}
    SDL_SetHint("SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT", "#canvas")

  # Create window
  let (bestW, bestH) = result.selectWindowSize()
  const SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000
  proc SDL_CreateWindow(title: cstring, x, y, w, h: int,
      flags: uint32): ptr SDLWindow
    {.importc, header: sdlH.}
  result.window = SDL_CreateWindow(title, SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED, bestW, bestH, 0)

  # Apply initial state
  result.setState(result.state)

  echo "initialized graphics"

proc `=destroy`(gfx: var Graphics) =
  proc SDL_DestroyWindow(window: ptr SDLWindow)
    {.importc, header: sdlH.}
  proc SDL_QuitSubSystem(flags: uint32)
    {.importc, header: sdlH.}
  if gfx.window != nil:
    SDL_DestroyWindow(gfx.window)
    SDL_QuitSubSystem(SDL_INIT_VIDEO)

  echo "deinitialized graphics"
