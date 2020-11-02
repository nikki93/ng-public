import std/times

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

    refreshBase: Time
    refreshCount: int
    refreshRate: int

    touches: seq[Touch]


# Init / deinit

const SDL_INIT_EVENTS = 0x00004000

proc initEvents*(gfx: var Graphics): Events =
  result.gfx = gfx

  # Refresh rate
  result.refreshBase = getTime()
  result.refreshCount = 1
  result.refreshRate = 60 # TODO(nikki): Read refresh rate from graphics

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
  # Maintain refresh rate by waiting till next beat. In Emscripten the
  # browser manages this for us.
  when not defined(emscripten):
    let refreshOffset = (1000 * ev.refreshCount div ev.refreshRate).milliseconds
    let sleepUntil = ev.refreshBase + refreshOffset
    let now = getTime()
    if sleepUntil > now:
      proc SDL_Delay(ms: uint32)
        {.importc, header: sdlH.}
      SDL_Delay(cast[uint32]((sleepUntil - now).inMilliseconds))
      inc ev.refreshCount
    else:
      ev.refreshBase = now
      ev.refreshCount = 1

var theFrameProc: proc()

template loop*(ev: var Events, body: untyped) =
  proc frameProc() =
    beginFrame(ev)
    body
    endFrame(ev)
  when defined(emscripten):
    theFrameProc = frameProc
    proc cFrame() {.cdecl.} =
      theFrameProc()
    proc emscripten_set_main_loop(
      x: proc() {.cdecl.},
      fps: int, simulateInfiniteLoop: bool)
      {.importc.}
    emscripten_set_main_loop(cFrame, 0, true)
  else:
    while not ev.quitting:
      frameProc()
