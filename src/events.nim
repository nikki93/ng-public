import graphics


const sdlH = "\"precomp.h\""

type
  SdlEventType {.importc: "SDL_EventType", header: sdlH.} = enum
    QuitEvent = 0x100

  SDLEvent {.importc: "SDL_Event", header: sdlH.} = object
    `type`: SdlEventType

  Touch = object
    id: int64
    screenX, screenY: float
    prevScreenX, prevScreenY: float
    screenDX, screenDY: float
    x, y: float
    dx, dy: float
    pressed: bool
    release: bool

  Events* = object
    gfx: Graphics

    quitting: bool

    touches: seq[Touch]


# Init / deinit

const SDL_INIT_EVENTS = 0x00004000

proc initEvents*(gfx: var Graphics): Events =
  result.gfx = gfx

  # Init SDL events
  proc SDL_InitSubSystem(flags: uint32): int
    {.importc, header: sdlH.}
  discard SDL_InitSubSystem(SDL_INIT_EVENTS)

  echo "initialized events"

proc `=destroy`(ev: var Events) =
  # Deinit SDL events
  proc SDL_QuitSubSystem(flags: uint32)
    {.importc, header: sdlH.}
  SDL_QuitSubSystem(SDL_INIT_EVENTS)

  echo "deinitialized events"


# Frame

proc beginFrame(ev: var Events) =
  var event: SDLEvent
  proc SDL_PollEvent(event: var SdlEvent): bool
    {.importc, header: sdlH.}
  while SDL_PollEvent(event):
    case event.`type`:
    of QuitEvent:
      ev.quitting = true

proc endFrame(ev: var Events) =
  discard

var theFrameProc = proc() = discard

template frame*(ev: var Events, body: untyped) =
  proc frame() =
    beginFrame(ev)
    body
    endFrame(ev)
  when defined(emscripten):
    theFrameProc = frame
    proc cFrame() {.cdecl.} =
      theFrameProc()
    proc emscripten_set_main_loop(
      x: proc() {.cdecl.},
      fps: int, simulateInfiniteLoop: bool)
      {.importc.}
    emscripten_set_main_loop(cFrame, 0, true)
  else:
    while not ev.quitting:
      frame()
