import std/[math, json]

import ng

import types, triggers
import saveload, editing, inspector


proc main() =
  initMeta()

  block: # Load scene
    loadScene("assets/test.scn")

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
    feet.shape.entity = ent

    let fric = ker.add(Friction, ent)
    fric.constr = phy.createPivot(phy.background, feet.body)
    fric.constr.maxForce = 800
    fric.constr.maxBias = 0

    discard ker.add(Player, ent)

  ev.loop: # Main event loop
    tim.frame() # Step time, skip frame if frame drop or not focused
    if tim.dt >= 3 * 1 / 60.0 or not ev.windowFocused:
      return

    # Update
    if edit.enabled:
      # Edit
      edit.frame()
    else:
      # Physics
      onPhysicsPre.run()
      phy.frame()
      onPhysicsPost.run()

    # Graphics
    gfx.frame:
      # Background color
      gfx.clear(0xcc, 0xe4, 0xf5)

      # Draw
      if edit.enabled:
        edit.applyView()
      else:
        discard # TODO(nikki): `onApplyView` trigger
      onDraw.run()
      onDrawOverlay.run()
      if edit.enabled:
        edit.draw()

    # UI
    ui.frame:
      # Top
      ui.patch("top"):
        ui.box("toolbar"):
          edit.toolbar()

        if edit.enabled:
          ui.box("small-gap")

          # Save button
          ui.button("save"):
            ui.event("click"):
              echo "saving scene..."
              echo saveScene().pretty

      # Side
      ui.patch("side"):
        edit.inspector()

      # Bottom
      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: ", $tim.fps.round.toInt

          ui.box("flex-gap")

          edit.status()

main()
