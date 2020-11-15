import std/math

import ng


type
  # Basics

  Position {.ng.} = object
    x, y: float

  Sprite {.ng.} = object
    image: Image
    #col, row: int
    #cols, rows: int
    scale: float
    depth: float
    #flipH: bool


  # Physics

  Feet {.ng.} = object
    body: Body
    shape: Shape
    offsetX, offsetY: float

  Walk {.ng.} = object
    target: Body
    constr: Constraint
    touchTime: float

  Friction {.ng.} = object
    constr: Constraint


  # Player

  Player {.ng.} = object


# Triggers

type Trigger = seq[proc()] # Track a bunch of procs to run at once

proc run(s: Trigger) =
  for fn in s:
    fn()

var onPhysicsPre: Trigger
var onPhysicsPost: Trigger

var onDraw: Trigger
var onDrawOverlay: Trigger


# Sprite

onDraw.add proc() =
  # Draw sprites in depth order
  ker.isort(Sprite, proc (a, b: ptr Sprite): bool {.cdecl.} =
    a.depth < b.depth)
  for _, spr, pos in ker.each(Sprite, Position):
    gfx.drawImage(spr.image, pos.x, pos.y, spr.scale)


# Player

onPhysicsPre.add proc() =
  # Walk player to touch
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
      echo "removed walk: reached target"
      continue
    let dot = vx * dx / dLen + vy * dy / dLen
    if dot <= 7: # Velocity along target direction too low, remove
      ker.remove(Walk, ent)
      echo "removed walk: obstructed"

onPhysicsPost.add proc() =
  # Read player physics
  for _, _, feet, pos in ker.each(Player, Feet, Position):
    let (x, y) = feet.body.position
    (pos.x, pos.y) = (x - feet.offsetX, y - feet.offsetY)

onPhysicsPost.add proc() =
  # Set player depth behind objects that obscure it
  discard

let footprintsImg = gfx.loadImage("assets/footprints.png")
onDrawOverlay.add proc() =
  # Draw footprints at player walk target
  for _, _, feet, walk in ker.each(Player, Feet, Walk):
    let (fx, fy) = feet.body.position
    let (wx, wy) = walk.target.position
    let (dx, dy) = (fx - wx, fy - wy)
    if dx * dx + dy * dy > 30 * 30: # Skip drawing if target too close
      gfx.drawImage(footprintsImg, wx, wy, 0.65)

onPhysicsPost.add proc() =
  # Update player animation based on walk state
  discard


# main

proc main() =
  initMeta()

  block: # Create player entity
    let ent = ker.create()

    let pos = ker.add(Position, ent)
    (pos.x, pos.y) = (100.0, 100.0)

    let spr = ker.add(Sprite, ent)
    spr.image = gfx.loadImage("assets/player.png")
    spr.scale = 0.25
    spr.depth = 1000

    let feet = ker.add(Feet, ent)
    feet.body = phy.createDynamic(1, Inf)
    feet.body.entity = ent
    feet.offsetY = 65.0
    feet.body.position = (pos.x, pos.y + feet.offsetY)
    const rad = 8.0
    feet.shape = phy.createBox(feet.body, 45 - 2 * rad, 20 - 2 * rad, rad)

    let fric = ker.add(Friction, ent)
    fric.constr = phy.createPivot(phy.getBackground(), feet.body)
    fric.constr.maxForce = 800
    fric.constr.maxBias = 0

    discard ker.add(Player, ent)

  ev.loop: # Main event loop
    tim.frame() # Step time, skip frame if frame drop or not focused
    if tim.dt >= 3 * 1 / 60.0 or not ev.windowFocused:
      return

    onPhysicsPre.run() # Step physics, running pre / post triggers
    phy.frame()
    onPhysicsPost.run()

    gfx.frame: # Draw graphics
      onDraw.run()
      onDrawOverlay.run()

    ui.frame: # Show UI
      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: " & $tim.fps.round.toInt

main()
