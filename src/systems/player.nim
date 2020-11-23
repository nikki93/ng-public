import std/math

import core

import types, triggers
import animation


# Walking

onPhysicsPre.add proc() =
  # Start / update walk on touch
  if ev.touches.len > 0:
    let touch = ev.touches[0]
    for ent, _, feet in ker.each(Player, Feet):
      var walk = ker.get(Walk, ent)
      if walk == nil:
        walk = ker.add(Walk, ent)
        walk.target = phy.createStatic()
        walk.constr = phy.createPivot(walk.target, feet.body)
        walk.constr.maxForce = 2000
        walk.constr.maxBias = 180
      walk.target.position = (touch.x, touch.y)
      walk.touchTime = tim.t

onPhysicsPost.add proc() =
  # Remove walk if player reached target or is obstructed
  for ent, _, feet, walk in ker.each(Player, Feet, Walk):
    if tim.t - walk.touchTime < 1: # Recently touched, keep walking
      continue
    let (vx, vy) = feet.body.velocity
    if vx * vx + vy * vy >= 20 * 20: # Moving fast enough, keep walking
      continue
    let (fx, fy) = feet.body.position
    let (wx, wy) = walk.target.position
    let (dx, dy) = (wx - fx, wy - fy)
    let dLen = sqrt(dx * dx + dy * dy)
    if dLen < 10: # We're there, remove
      ker.remove(Walk, ent)
      continue
    let dot = vx * dx / dLen + vy * dy / dLen
    if dot <= 7: # Velocity along target direction too low, remove
      ker.remove(Walk, ent)


# Reading physics

onPhysicsPost.add proc() =
  for _, _, feet, pos in ker.each(Player, Feet, Position):
    let (x, y) = feet.body.position
    (pos.x, pos.y) = (x - feet.offsetX, y - feet.offsetY)


# Depth

onPhysicsPost.add proc() =
  # Set player depth behind objects that obscure it
  for ent, _, feet, spr in ker.each(Player, Feet, Sprite):
    spr.depth = 1000
    template query(x, y: float) =
      for res in phy.segmentQuery((x, y), (x, y + 1e4), 1):
        if res.entity != nullEntity and res.entity != ent:
          let otherSpr = ker.get(Sprite, res.entity)
          if otherSpr != nil:
            spr.depth = min(spr.depth, otherSpr.depth - 0.2)
    let (x, y) = feet.body.position
    query(x + 22, y)
    query(x - 22, y)
    query(x, y)


# Animation

onPhysicsPost.add proc() =
  # Update player animation based on walk state
  for ent, _, spr, anim in ker.each(Player, Sprite, Animation):
    if ker.has(Walk, ent):
      let feet = ker.get(Feet, ent)
      let (vx, vy) = feet.body.velocity
      if vx * vx + vy * vy >= 27:
        spr.flipH = vx < 0
        anim.setClip("walk_right")
        continue
    anim.setClip("idle")


# Draw overlay

let footprintsImg = gfx.loadImage("assets/footprints.png")
onDrawOverlay.add proc() =
  # Draw footprints at player walk target
  for _, _, feet, walk in ker.each(Player, Feet, Walk):
    let (fx, fy) = feet.body.position
    let (wx, wy) = walk.target.position
    let (dx, dy) = (fx - wx, fy - wy)
    if dx * dx + dy * dy > 30 * 30: # Skip drawing if target too close
      gfx.drawImage(footprintsImg, wx, wy, 0.65)
