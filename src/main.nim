import std/math

import boot

import timing, graphics, events, uis, physics


proc main() =
  let playerBody = phy.createDynamic(1.0, Inf)
  playerBody.position = (100.0, 100.0)
  const radius = 8.0
  let (playerW, playerH) = (45.0 - 2 * radius, 20.0 - 2 * radius)
  let playerShape = phy.createBox(playerBody, playerW, playerH, radius)

  let frictionConstr = phy.createPivot(phy.getBackground(), playerBody)
  frictionConstr.maxForce = 800
  frictionConstr.maxBias = 0

  let playerImg = gfx.loadImage("assets/player.png")
  let playerEff = gfx.loadEffect("test.frag")

  type
    Walk = object
      target: Body
      constr: Constraint
  var walk: ref Walk

  var playing = true

  ev.loop:
    tim.frame()
    if tim.dt >= 3 * 1 / 60.0: # Frame drop
      return

    if not ev.windowFocused:
      return

    if playing:
      if ev.touches.len == 1:
        let touch = ev.touches[0]
        if touch.pressed:
          let target = phy.createStatic()
          let constr = phy.createPivot(target, playerBody)
          constr.maxForce = 2000
          constr.maxBias = 180
          walk = (ref Walk)(target: target, constr: constr)
        if walk != nil:
          walk.target.position = (touch.x, touch.y)
        if touch.released:
          walk = nil

      phy.frame()

    gfx.frame:
      gfx.clear(0xcc, 0xe4, 0xf5)

      gfx.scope:
        #gfx.useEffect(playerEff)
        #playerEff.set("u_time", tim.t)
        let (x, y) = playerBody.position
        const playerOffsetY = 65.0
        gfx.drawImage(playerImg, x, y - playerOffsetY, 0.25)

    ui.frame:
      ui.patch("top"):
        ui.box("toolbar"):
          ui.button(class = if playing: "stop" else: "play"):
            ui.event("click"):
              playing = not playing

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
