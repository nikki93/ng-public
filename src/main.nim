import std/math

import boot

import timing, graphics, events


ev.loop:
  tim.frame

  gfx.frame:
    let r = 0xff * (tim.t - tim.t.floor)
    gfx.clear(cast[uint8](r.toInt), 0xe4, 0xf5)
