## Keeps track of elapsed time.

import std/times


type
  Timing = object
    start: Time
    seconds: float
    lastFrame: Time
    deltaSeconds: float

    lastFPSUpdate: Time
    framesSinceFPSUpdate: int
    fps*: float


# Time

proc t*(tim: Timing): float {.inline.} =
  ## Time elapsed in seconds since the start of the application.
  tim.seconds

proc dt*(tim: Timing): float {.inline.} =
  ## Time elapsed in seconds since the last frame.
  tim.deltaSeconds


# Frame

func inSecondsFloat(dur: Duration): float =
  1.0e-6 * dur.inMicroseconds.toBiggestFloat

proc frame*(tim: var Timing) =
  ## Notify the timing system about one frame passing. Usually this is done
  ## once at the beginning of each frame of the event loop (see `events`).

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


# Init / deinit

proc init*(tim: var Timing) =
  tim.start = getTime()
  tim.lastFrame = tim.start
  tim.lastFPSUpdate = tim.start

  echo "initialized timing"

proc deinit*(tim: var Timing) =
  echo "deinitialized timing"


# Singleton

proc `=copy`(a: var Timing, b: Timing) {.error.}

var tim*: Timing ## The global instance of this module to pass to procedures.
