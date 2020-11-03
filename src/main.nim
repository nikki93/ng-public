import std/math

import boot

import timing, graphics, events


ev.loop:
  tim.frame

  if ev.touches.len > 0:
    var msg = "touches: "
    for touch in ev.touches:
      msg.add($touch)
      msg.add(", ")
    echo msg

  gfx.frame:
    let r = 0xff * (0.2 * (sin(2 * tim.t) + 1) + 0.1)
    let rU8 = cast[uint8](r.toInt)
    if ev.touches.len > 0:
      gfx.clear(rU8, 0x80, 0x20)
    else:
      gfx.clear(rU8, 0x20, 0x80)
