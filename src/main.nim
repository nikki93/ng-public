import std/math

import boot

import timing, graphics, events, uis, physics


proc main() =
  let testImg = gfx.loadImage("assets/player.png")
  let testEff = gfx.loadEffect("test.frag")

  const (screenW, screenH) = (800.0, 450.0)

  phy.gravity = (0.0, 9.8 * 32)

  const (floorW, floorH) = (screenW, 20.0)
  let floorBody = phy.createStatic()
  floorBody.position = (0.5 * screenW, 450.0 - 0.5 * floorH)
  let floorShape = phy.createBox(floorBody, floorW, floorH)

  const (boxW, boxH) = (80.0, 80.0)
  let boxBody = phy.createDynamic(1.0, Inf)
  boxBody.position = (0.5 * screenW, 0.5 * boxH + 20.0)
  let boxShape = phy.createBox(boxBody, 80.0, 80.0)

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
        let constr = phy.createPivot(target, boxBody)
        walk = (ref Walk)(target: target, constr: constr)
      if walk != nil:
        walk.target.position = (touch.x, touch.y)
      if touch.released:
        walk = nil

    phy.frame()

    gfx.frame:
      gfx.scope:
        gfx.useEffect(testEff)
        testEff.set("u_time", tim.t)
        gfx.drawImage(testImg, 100, 200, 0.4)

      gfx.scope:
        gfx.setColor(0xff, 0, 0xff)
        let (x, y) = boxBody.position
        gfx.drawRectangleFill(x, y, boxW, boxH)

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
