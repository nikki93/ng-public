import times


type
  Timing* = object
    start: Time
    seconds: float
    lastFrame: Time
    deltaSeconds: float

    lastFPSUpdate: Time
    framesSinceFPSUpdate: int
    fps: float


# Time

proc t*(tim: Timing): float {.inline.} =
  tim.seconds

proc dt*(tim: Timing): float {.inline.} =
  tim.deltaSeconds


# Init / deinit

proc initTiming*(): Timing =
  result.start = getTime()
  result.lastFrame = result.start
  result.lastFPSUpdate = result.start


# Frame

proc frame*(tim: var Timing) =
  # Time
  let now = getTime()
  tim.seconds = 1.0e-6 *
    (now - tim.start).inMicroseconds.toBiggestFloat
  tim.deltaSeconds = 1.0e-6 *
    (now - tim.lastFrame).inMicroseconds.toBiggestFloat
  tim.lastFrame = now

  # FPS
  inc tim.framesSinceFPSUpdate
  let secSinceFPSUpdate = (now - tim.lastFPSUpdate).inSeconds.toBiggestFloat
  if secSinceFPSUpdate > 1:
    tim.lastFPSUpdate = now
    tim.fps = tim.framesSinceFPSUpdate.toFloat / secSinceFPSUpdate
    tim.framesSinceFPSUpdate = 0
    echo "fps: ", tim.fps
