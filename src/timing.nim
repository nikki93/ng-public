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


# Init / deinit

proc initTiming*(): Timing =
  result.start = getTime()
  result.lastFrame = result.start
  result.lastFPSUpdate = result.start
  

# Frame

proc frame*(tim: var Timing) =
  # Time
  let now = getTime()
  tim.seconds = (now - tim.start).inSeconds.toBiggestFloat
  tim.deltaSeconds = (now - tim.lastFrame).inSeconds.toBiggestFloat
  tim.lastFrame = now

  # FPS
  inc tim.framesSinceFPSUpdate
  let secSinceFPSUpdate = (now - tim.lastFPSUpdate).inSeconds.toBiggestFloat
  if secSinceFPSUpdate > 1:
    tim.lastFPSUpdate = now
    tim.fps = tim.framesSinceFPSUpdate.toFloat / secSinceFPSUpdate
    tim.framesSinceFPSUpdate = 0
    echo "fps: ", tim.fps
