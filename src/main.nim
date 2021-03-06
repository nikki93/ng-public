import std/[math, json]

import core

import types, triggers
import systems/all
import saveload, saveload_impl
import editing, inspector


proc main() =
  initMeta()

  block: # Load scene
    loadScene("assets/test.scn")

  block: # Create player entity
    let ent = ker.create()

    let pos = ker.add(Position, ent)
    (pos.x, pos.y) = (230.0, 115.0)

    let spr = ker.add(Sprite, ent)
    spr.image = gfx.loadImage("assets/player_walk_right.png")
    spr.cols = 4
    spr.rows = 2
    spr.scale = 0.37
    spr.depth = 1000

    let anim = ker.add(Animation, ent)
    anim.addClip(AnimationClip(
      name: "idle",
      count: 1,
      fps: 24,
    ))
    anim.addClip(AnimationClip(
      name: "walk_right",
      count: 8,
      fps: 12,
    ))

    let feet = ker.add(Feet, ent)
    feet.body = phy.createDynamic(1, Inf)
    feet.body.entity = ent
    feet.offsetY = 65.0
    feet.body.position = (pos.x, pos.y + feet.offsetY)
    const rad = 8.0
    feet.shape = phy.createBox(feet.body, 45 - 2 * rad, 20 - 2 * rad, rad)
    feet.shape.entity = ent

    let fric = ker.add(Friction, ent)
    load(fric[], ent, JsonNode())

    let vf = ker.add(ViewFollow, ent)
    (vf.x, vf.y) = (pos.x, pos.y)
    vf.offsetY = 30
    vf.border = 180
    vf.rate = 8

    discard ker.add(Player, ent)

  block: # Save starting undo point
    # TODO(nikki): Need to not do this when no editor
    edit.clearActions()
    edit.checkpoint("loaded scene")

  ev.loop: # Main event loop
    tim.frame() # Step time, skip frame if frame drop or not focused
    if tim.dt >= 3 * 1 / 60.0 or not ev.windowFocused:
      return

    block: # In edit only run loop on I/O
      var framesSinceIO {.global.} = 0
      if edit.enabled and ev.touches.len == 0 and ui.noEvents:
        if framesSinceIO > 2:
          return
        else:
          inc framesSinceIO
      else:
        framesSinceIO = 0

    # Update
    if edit.enabled:
      # Edit
      edit.frame()
    else:
      # Physics
      onPhysicsPre.run()
      phy.frame()
      onPhysicsPost.run()

      # Animation
      onAnimate.run()

    # Graphics
    gfx.frame:
      # Background color
      gfx.clear(0xcc, 0xe4, 0xf5)

      # Draw
      if edit.enabled:
        edit.applyView()
      else:
        onApplyView.run()
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
              let node = saveScene(
                filter = proc(ent: Entity): bool =
                not ker.has(Player, ent))
              echo node.pretty

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
