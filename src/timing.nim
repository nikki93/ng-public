import std/[times, math]


type
  Timing = object
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

proc init(tim: var Timing) =
  tim.start = getTime()
  tim.lastFrame = tim.start
  tim.lastFPSUpdate = tim.start

  echo "initialized timing"

proc `=destroy`(tim: var Timing) =
  echo "deinitialized timing"


# Frame

func inSecondsFloat(dur: Duration): float =
  1.0e-6 * dur.inMicroseconds.toBiggestFloat

proc frame*(tim: var Timing) =
  # Time
  let now = getTime()
  tim.seconds = (now - tim.start).inSecondsFloat
  tim.deltaSeconds = (now - tim.lastFrame).inSecondsFloat
  tim.lastFrame = now

  # FPS
  inc tim.framesSinceFPSUpdate
  let secSinceFPSUpdate = (now - tim.lastFPSUpdate).inSecondsFloat
  if secSinceFPSUpdate > 1:
    tim.lastFPSUpdate = now
    tim.fps = tim.framesSinceFPSUpdate.toFloat / secSinceFPSUpdate
    tim.framesSinceFPSUpdate = 0
    echo "fps: ", tim.fps.round.toInt


# Singleton

proc `=copy`(a: var Timing, b: Timing) {.error.}

var tim*: Timing
tim.init()
