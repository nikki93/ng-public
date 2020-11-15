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
  if ev.touches.len > 0:
    # Touching: add walk if needed and update it
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
  else: # Not touching: remove walk
    for ent, _, _ in ker.each(Player, Walk):
      ker.remove(Walk, ent)

onPhysicsPost.add proc() =
  # Remove walk if reached target or obstructed
  discard

onPhysicsPost.add proc() =
  # Read player physics
  for _, _, feet, pos in ker.each(Player, Feet, Position):
    let (x, y) = feet.body.position
    (pos.x, pos.y) = (x - feet.offsetX, y - feet.offsetY)

onPhysicsPost.add proc() =
  # Set player depth behind objects that obscure it
  discard

onDrawOverlay.add proc() =
  # Draw player footprints at target when walking
  discard

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
