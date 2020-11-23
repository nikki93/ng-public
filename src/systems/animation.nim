import std/decls

import ng

import types, triggers


# Animating

onAnimate.add proc() =
  for _, anim, spr in ker.each(Animation, Sprite):
    if anim.clipIndex < anim.clips.len:
      let clip {.byaddr.} = anim.clips[anim.clipIndex]

      # Tick time, wrapping at total time
      anim.time += tim.dt
      let totalTime = clip.pause + clip.count.toFloat / clip.fps
      while anim.time > totalTime:
        anim.time -= totalTime

      # Calculate subimage, wrapping at total number of columns
      let frame = int(max(0, (anim.time - clip.pause) * clip.fps))
      spr.col = clip.start + frame mod clip.count
      spr.row = spr.col div spr.cols
      spr.col = spr.col mod spr.cols
