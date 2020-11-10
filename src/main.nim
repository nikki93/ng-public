import std/math

import boot

import timing, graphics, events, uis, physics


proc main() =
  let playerBody = phy.createDynamic(1.0, Inf)
  playerBody.setPosition((100.0, 100.0))
  const radius = 8.0
  let (playerW, playerH) = (45.0 - 2 * radius, 20.0 - 2 * radius)
  let playerShape = phy.createBox(playerBody, playerW, playerH, radius)

  let frictionConstr = phy.createPivot(phy.getBackground(), playerBody)
  frictionConstr.setMaxForce(800)
  frictionConstr.setMaxBias(0)

  let playerImg = gfx.loadImage("assets/player.png")
  let playerEff = gfx.loadEffect("test.frag")

  type
    Walk = object
      target: Body
      constr: Constraint
  var walk: ref Walk

  ev.loop:
    tim.frame()
    if tim.dt >= 3 * 1 / 60.0: # Frame drop
      return

    if not ev.windowFocused:
      return

    if ev.touches.len == 1:
      let touch = ev.touches[0]
      if touch.pressed:
        let target = phy.createStatic()
        let constr = phy.createPivot(target, playerBody)
        constr.setMaxForce(2000)
        constr.setMaxBias(180)
        walk = (ref Walk)(target: target, constr: constr)
      if walk != nil:
        walk.target.setPosition((touch.x, touch.y))
      if touch.released:
        walk = nil

    phy.frame()

    gfx.frame:
      gfx.clear(0xcc, 0xe4, 0xf5)

      gfx.scope:
        #gfx.useEffect(playerEff)
        #playerEff.set("u_time", tim.t)
        let (x, y) = playerBody.getPosition()
        const playerOffsetY = 65.0
        gfx.drawImage(playerImg, x, y - playerOffsetY, 0.25)

    ui.frame:
      ui.patch("top"):
        ui.box("toolbar"):
          ui.button("play"):
            ui.event("click"):
              echo "clicked!"

      ui.patch("side"):
        ui.box("inspector"):
          ui.elem("details", open = true):
            ui.elem("summary"):
              ui.text "position"
            ui.box("info"):
              ui.elem("input"):
                ui.event("change"):
                  echo "value is now: '", ui.valueStr, "'"

      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: " & $tim.fps.round.toInt

main()
