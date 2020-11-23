import std/[decls, json, hashes]

import core

import types, triggers


# Interface

proc addClip*(anim: ptr Animation, clip: AnimationClip) =
  anim.clipNameHashes.add(hash(clip.name))
  anim.clips.add(clip)

proc setClip*(anim: ptr Animation, name: static string) =
  const nameHash = hash(name)
  if anim.clipIndex < anim.clips.len:
    if anim.clipNameHashes[anim.clipIndex] == nameHash:
      return # Assuming a collision is unlikely...
  for i in 0..<anim.clips.len:
    if anim.clipNameHashes[i] == nameHash and anim.clips[i].name == name:
      anim.clipIndex = i


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


# Loading / saving

proc load*(anim: var Animation, ent: Entity, node: JsonNode) =
  # Re-generate clip name hashes
  anim.clipNameHashes.setLen(anim.clips.len)
  for i in 0..<anim.clips.len:
    anim.clipNameHashes[i] = hash(anim.clips[i].name)

proc save*(anim: Animation, ent: Entity, node: JsonNode) =
  # Skip clip name hashes (should re-generate)
  node.delete("clipNameHashes")
