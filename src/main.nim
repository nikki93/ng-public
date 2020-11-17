import all


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
