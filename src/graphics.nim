const sdlH = "\"precomp.h\""

const gpuH = "\"precomp.h\""

type
  SDLWindow {.importc: "SDL_Window", header: sdlH.} = object

  SDLColor {.importc: "SDL_Color", header: sdlH.} = object
    r, g, b, a: uint8

  GPURect {.importc: "GPU_Rect", header: gpuH.} = object
    x, y, w, h: float32

  GPUTarget {.importc: "GPU_Target", header: gpuH.} = object
    w: uint16

  State = object
    r, g, b, a: uint8
    viewX, viewY: float
    viewWidth, viewHeight: float

  Graphics = object
    window: ptr SDLWindow
    screen: ptr GPUTarget

    renderScale: float
    state: State



# Coordinates

proc SDL_GetWindowSize(window: ptr SDLWindow, w, h: var cint)
  {.importc, header: sdlH.}

proc GPU_SetWindowResolution(w, h: uint16)
  {.importc, header: gpuH.}

proc view*(gfx: Graphics): (float, float, float, float) {.inline.} =
  (result[0], result[1]) = (gfx.state.viewX, gfx.state.viewY)
  (result[2], result[3]) = (gfx.state.viewWidth, gfx.state.viewHeight)

proc viewToWorld*(gfx: Graphics, x, y: float): (float, float) {.inline.} =
  result[0] = x - 0.5 * gfx.state.viewWidth + gfx.state.viewX
  result[1] = y - 0.5 * gfx.state.viewHeight + gfx.state.viewY

proc windowSize*(gfx: Graphics): (float, float) {.inline.} =
  var w, h: cint
  SDL_GetWindowSize(gfx.window, w, h)
  (w.toFloat, h.toFloat)

proc selectWindowSize(gfx: var Graphics): (int, int) =
  var bestW = 800
  # TODO(nikki): Use canvas width in Emscripten (see C++ engine code)
  (bestW, (bestW.toFloat * gfx.state.viewHeight / gfx.state.viewWidth).toInt)

proc updateRenderScale(gfx: var Graphics) =
  let screenW = cast[int](gfx.screen.w).toBiggestFloat
  gfx.renderScale = screenW / gfx.state.viewWidth


# State

proc setColor*(gfx: var Graphics, r, g, b: uint8, a: uint8 = 0xff) =
  (gfx.state.r, gfx.state.g, gfx.state.b, gfx.state.a) = (r, g, b, a)

proc setView*(gfx: var Graphics, x, y, w, h: float) =
  (gfx.state.viewX, gfx.state.viewY) = (x, y)
  (gfx.state.viewWidth, gfx.state.viewHeight) = (w, h)
  gfx.updateRenderScale()

proc setState*(gfx: var Graphics, state: State) =
  gfx.setColor(state.r, state.g, state.b, state.a)
  gfx.setView(state.viewX, state.viewY, state.viewWidth, state.viewHeight)


# Init / deinit

const SDL_INIT_VIDEO = 0x00000020

proc init(gfx: var Graphics) =
  # Initial state
  gfx.renderScale = 1
  gfx.state = State(
    r: 0xff, g: 0xff, b: 0xff, a: 0xff,
    viewX: 400, viewY: 225,
    viewWidth: 800, viewHeight: 450)

  # Init SDL video
  proc SDL_InitSubSystem(flags: uint32): int
    {.importc, header: sdlH.}
  discard SDL_InitSubSystem(SDL_INIT_VIDEO)

  # In Emscripten, tell SDL to only take keyboard focus when the canvas is
  # focused. Without this it steals keyboard focus from the whole page.
  when defined(emscripten):
    proc SDL_SetHint(nane: cstring, value: cstring): bool
      {.importc, header: sdlH.}
    discard SDL_SetHint("SDL_EMSCRIPTEN_KEYBOARD_ELEMENT", "#canvas")

  # Create window
  let (bestW, bestH) = gfx.selectWindowSize()
  proc SDL_CreateWindow(title: cstring, x, y, w, h: int,
      flags: uint32): ptr SDLWindow
    {.importc, header: sdlH.}
  const SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000
  const SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000
  const SDL_WINDOW_OPENGL = 0x00000002
  gfx.window = SDL_CreateWindow("ng",
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      bestW, bestH,
      SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_OPENGL)

  # Create renderer
  proc SDL_GetWindowID(window: ptr SDLWindow): uint32
    {.importc, header: sdlH.}
  proc GPU_SetInitWindow(windowId: uint32)
    {.importc, header: gpuH.}
  GPU_SetInitWindow(SDL_GetWindowID(gfx.window))
  var w, h: cint
  SDL_GetWindowSize(gfx.window, w, h)
  proc GPU_Init(w, h: uint16, flags: uint32): ptr GPUTarget
    {.importc, header: gpuH.}
  const GPU_DEFAULT_INIT_FLAGS = 0
  gfx.screen = GPU_Init(cast[uint16](w), cast[uint16](h),
    GPU_DEFAULT_INIT_FLAGS)
  GPU_SetWindowResolution(cast[uint16](w), cast[uint16](h))

  # Apply initial state
  gfx.setState(gfx.state)

  echo "initialized graphics"

proc `=destroy`(gfx: var Graphics) =
  # TODO(nikki): Deinitialize resources here, /before/ the rest

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

proc worldToRender(gfx: Graphics, x, y: float): (float, float) {.inline.} =
  ## Render-transformed coordinates to pass to renderer
  result[0] = gfx.renderScale *
    (x + 0.5 * gfx.state.viewWidth - gfx.state.viewX)
  result[1] = gfx.renderScale *
    (y + 0.5 * gfx.state.viewHeight - gfx.state.viewY)

proc gpuRect(gfx: var Graphics, x, y, w, h: float): GPURect {.inline.} =
  ## Render-transformed `GPU_Rect` to pass to renderer
  (result.x, result.y) = gfx.worldToRender(x - 0.5 * w, y - 0.5 * h)
  (result.w, result.h) = (gfx.renderScale * w, gfx.renderScale * h)

proc sdlColor(gfx: var Graphics): SDLColor {.inline.} =
  ## Current `SDLColor` to pass to renderer
  SDLColor(r: gfx.state.r, g: gfx.state.g, b: gfx.state.b, a: gfx.state.a)

proc drawLine*(gfx: var Graphics, x1, y1, x2, y2: float) =
  proc GPU_Line(target: ptr GPUTarget,
    x1, y1, x2, y2: float32, color: SDLColor)
    {.importc, header: gpuH.}
  let (rx1, ry1) = gfx.worldToRender(x1, y1)
  let (rx2, ry2) = gfx.worldToRender(x2, y2)
  GPU_Line(gfx.screen, rx1, ry1, rx2, ry2, gfx.sdlColor)

proc drawRectangle*(gfx: var Graphics, x, y, w, h: float) =
  proc GPU_Rectangle2(target: ptr GPUTarget,
    rect: GPURect, color: SDLColor)
    {.importc, header: gpuH.}
  GPU_Rectangle2(gfx.screen, gfx.gpuRect(x, y, w, h), gfx.sdlColor)

proc drawRectangleFill*(gfx: var Graphics, x, y, w, h: float) =
  proc GPU_RectangleFilled2(target: ptr GPUTarget,
    rect: GPURect, color: SDLColor)
    {.importc, header: gpuH.}
  GPU_RectangleFilled2(gfx.screen, gfx.gpuRect(x, y, w, h), gfx.sdlColor)

template scope*(gfx: var Graphics, body: typed) =
  let oldState = gfx.state
  body
  setState(gfx, oldState)


# Frame

proc beginFrame(gfx: var Graphics) =
  # Update window and renderer size if needed
  let (bestW, bestH) = gfx.selectWindowSize()
  var w, h: cint
  SDL_GetWindowSize(gfx.window, w, h)
  if w != bestW or h != bestH:
    proc SDL_SetWindowSize(window: ptr SDLWindow, w, h: int)
      {.importc, header: sdlH.}
    SDL_SetWindowSize(gfx.window, bestW, bestH)
    GPU_SetWindowResolution(cast[uint16](bestW), cast[uint16](bestH))
    echo "updated window size to (", bestW, ", ", bestH, ")"

  gfx.updateRenderScale()

  gfx.clear(0xff, 0xff, 0xff)

proc endFrame(gfx: var Graphics) =
  proc GPU_Flip(target: ptr GPUTarget)
    {.importc, header: gpuH.}
  GPU_Flip(gfx.screen)

template frame*(gfx: var Graphics, body: typed) =
  beginFrame(gfx)
  scope(gfx, body)
  endFrame(gfx)


# Singleton

proc `=copy`(a: var Graphics, b: Graphics) {.error.}

var gfx*: Graphics
gfx.init()
