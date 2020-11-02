import std/math

import common
import timing, graphics, events


ev.loop:
  tim.frame

  gfx.frame:
    gfx.clear(cast[uint8]((0xff * (tim.t - tim.t.floor)).toInt), 0xe4, 0xf5)
