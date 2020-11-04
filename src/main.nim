import std/math

import boot

import timing, graphics, events


ev.loop:
  tim.frame

  if ev.touches.len > 0:
    echo "num touches: ", ev.touches.len
    for touch in ev.touches:
      echo "touch ", touch.id, ": ", $touch

  gfx.frame:
    let r = 0xff * (0.2 * (sin(2 * tim.t) + 1) + 0.1)
    let rU8 = cast[uint8](r.toInt)
    if ev.touches.len > 0:
      gfx.clear(rU8, 0x80, 0x20)
    else:
      gfx.clear(rU8, 0x20, 0x80)

    gfx.drawLine(100, 100, 400, 300)
    gfx.drawRectangle(200, 200, 80, 80)
    gfx.drawRectangleFill(400, 200, 80, 80)
