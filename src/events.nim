## Manages the window event loop and provides access to input events.

import std/[times, sequtils]


import graphics, utils


const sdlH = "\"precomp.h\""

type
  SDLEventType {.importc: "SDL_EventType", header: sdlH.} = enum
    Quit = 0x100

    MouseMotion = 0x400
    MouseButtonDown
    MouseButtonUp

    FingerDown = 0x700
    FingerUp
    FingerMotion

  SDLMouseButtonEvent
    {.importc: "SDL_MouseMotionEvent", header: sdlH.} = object
    x: int32
    y: int32

  SDLTouchFingerEvent
    {.importc: "SDL_TouchFingerEvent", header: sdlH.} = object
    fingerId: int64
    x: float32
    y: float32

  SDLEvent {.union, importc: "SDL_Event", header: sdlH.} = object
    `type`: SDLEventType
    button: SDLMouseButtonEvent
    tfinger: SDLTouchFingerEvent

  Touch = object
    id*: int64                  ## Unique id distinguishing this touch from
                                ## other ones in a multi-touch gesture.
    screenX*, screenY*: float   ## The touch coordinates in view-space.
    prevScreenX, prevScreenY: float
    screenDX*, screenDY*: float ## Change of view-space coordinates in the
                                ## last frame.
    x*, y*: float               ## Touch coordinates in world space.
    dx*, dy*: float             ## Change of world-space coordinates in the
                                ## last frame.
    pressed*: bool              ## Whether the touch just began in this frame.
    released*: bool             ## Whether the touch just ended in this frame.

  Events = object
    quitting: bool
    prevUnfocused: bool

    refreshBase: Time
    refreshCount: int
    refreshRate: int

    touches*: seq[Touch] ## The currently active touches.


# Focus

proc windowFocused*(ev: Events): bool {.inline.} =
  ## Whether the window currently has keyboard focus
  when defined(emscripten):
    proc JS_isWindowFocused(): bool
      {.importc.}
    JS_isWindowFocused()
  else:
    true


# Init / deinit

const SDL_INIT_EVENTS = 0x00004000

proc init(ev: var Events) =
  # Refresh rate
  ev.refreshBase = getTime()
  ev.refreshCount = 1
  ev.refreshRate = 60 # TODO(nikki): Read refresh rate from graphics

  # Tell SDL not to consider touches as mouse events since we check both
  proc SDL_SetHint(nane: cstring, value: cstring): bool
    {.importc, header: sdlH.}
  discard SDL_SetHint("SDL_TOUCH_MOUSE_EVENTS", "0")

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

  destroyFields(ev)
  echo "deinitialized events"


# Frame

proc addTouch(ev: var Events, id: int64, screenX, screenY: float) {.inline.} =
  ev.touches.keepItIf(it.id != id)
  let (x, y) = gfx.viewToWorld(screenX, screenY)
  ev.touches.add(Touch(
    id: id,
    screenX: screenX, screenY: screenY,
    prevScreenX: screenX, prevScreenY: screenY,
    x: x, y: y,
    pressed: true,
  ))

proc setTouch(ev: var Events,
  id: int64, screenX, screenY: float, released: bool) {.inline.} =
  for touch in ev.touches.mitems:
    if touch.id == id:
      touch.screenX = screenX
      touch.screenY = screenY
      if released:
        touch.released = true

proc beginFrame(ev: var Events) =
  # Check SDL events
  var event: SDLEvent
  proc SDL_PollEvent(event: var SdlEvent): bool
    {.importc, header: sdlH.}
  while SDL_PollEvent(event):
    case event.type:
      # Quit
    of Quit:
      ev.quitting = true

      # Mouse
    of MouseButtonDown, MouseMotion, MouseButtonUp:
      const id = -1 # Based on `SDL_MOUSE_TOUCHID`
      let (ww, wh) = gfx.windowSize
      let (_, _, vw, vh) = gfx.view
      let screenX = event.button.x.toFloat * vw / ww;
      let screeny = event.button.y.toFloat * vh / wh;
      if event.type == MouseButtonDown:
        ev.addTouch(id, screenX, screenY)
      else:
        ev.setTouch(id, screenX, screenY, event.type == MouseButtonUp)

      # Touch
    of FingerDown, FingerMotion, FingerUp:
      let id = event.tfinger.fingerId
      let (ww, wh) = gfx.windowSize
      let (_, _, vw, _) = gfx.view
      let screenX = event.tfinger.x * vw;
      let screenY = event.tfinger.y * wh * vw / ww;
      if event.type == FingerDown:
        ev.addTouch(id, screenX, screenY)
      else:
        ev.setTouch(id, screenX, screenY, event.type == FingerUp)

  # Update touch deltas and world-space coordinates
  for touch in ev.touches.mitems:
    touch.screenDX = touch.screenX - touch.prevScreenX
    touch.screenDY = touch.screenY - touch.prevScreenY
    touch.prevScreenX = touch.screenX
    touch.prevScreenY = touch.screenY
    let (newX, newY) = gfx.viewToWorld(touch.screenX, touch.screenY)
    touch.dx = newX - touch.x
    touch.dy = newY - touch.y
    touch.x = newX
    touch.y = newY

const maintainRefreshRate = false

proc endFrame(ev: var Events) =
  # Remove released touches
  ev.touches.keepItIf(not it.released)

  # Reset pressed state
  for touch in ev.touches.mitems:
    touch.pressed = false

  # Maintain refresh rate by waiting till next beat. In Emscripten the
  # browser manages the frame rate and we don't have to do this.
  when maintainRefreshRate and not defined(emscripten):
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

  # In Emscripten, sleep more when window isn't focused to reduce CPU usage.
  when defined(emscripten):
    const
      EM_TIMING_SETTIMEOUT = 0
      EM_TIMING_RAF = 1
    proc emscripten_set_main_loop_timing(mode, value: int): int
      {.importc, discardable.}
    let unfocused = not ev.windowFocused()
    if unfocused != ev.prevUnfocused:
      if unfocused:
        emscripten_set_main_loop_timing(EM_TIMING_SETTIMEOUT, 100)
      else:
        emscripten_set_main_loop_timing(EM_TIMING_RAF, 0)
      ev.prevUnfocused = unfocused

var theFrameProc: proc() # Needed for the Emscripten case below

template loop*(ev: var Events, body: typed) =
  ## Begin the application's event loop, running the body every frame of the
  ## event loop. Events are only accessible within this body.
  block:
    # Run this on each iteration
    proc frameProc() =
      beginFrame(ev)
      body
      endFrame(ev)

    when defined(emscripten):
      # Emscripten maanges the main loop and needs us to just pass it a
      # frame callback
      theFrameProc = frameProc
      proc cFrame() {.cdecl.} =
        theFrameProc()
      proc emscripten_set_main_loop(
        x: proc() {.cdecl.},
        fps: int, simulateInfiniteLoop: bool)
        {.importc.}
      emscripten_set_main_loop(cFrame, 0, true)
    else:
      # Regular loop
      while not ev.quitting:
        frameProc()


# Singleton

proc `=copy`(a: var Events, b: Events) {.error.}

var ev*: Events ## The global instance of this module to pass to procedures.
ev.init()
