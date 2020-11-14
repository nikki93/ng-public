import std/[math, random]

import ng


type
  Box {.ng.} = object
    body: Body
    shape: Shape


proc main() =
  initMeta()

  const (screenW, screenH) = (800.0, 450.0)

  phy.gravity = (0.0, 9.8 * 64)

  let wallThickness = 40.0

  let floorBody = phy.createStatic()
  floorBody.position = (0.5 * screenW, 450.0 - 0.5 * wallThickness)
  let floorShape = phy.createBox(floorBody, screenW, wallThickness)

  const (boxW, boxH) = (40.0, 40.0)
  for i in 1..200:
    let ent = ker.create()
    let box = ker.add(Box, ent)
    box.body = phy.createDynamic(1, Inf)
    box.body.position = (rand(screenW), rand(100.0..(screenH - 100.0)))
    box.shape = phy.createBox(box.body, boxW, boxH)
    box.shape.entity = ent

  ev.loop:
    tim.frame()
    if tim.dt >= 3 * 1 / 60.0: # Frame drop
      return

    if not ev.windowFocused:
      return

    if ev.touches.len == 1:
      let touch = ev.touches[0]
      for res in phy.segmentQuery((touch.x, touch.y), (touch.x, touch.y + 1)):
        if res.entity != null:
          ker.destroy(res.entity)

    phy.frame(fixedTimeStep = true)

    gfx.frame:
      for _, box in ker.each(Box):
        let (x, y) = box.body.position
        gfx.drawRectangleFill(x, y, boxW, boxH)
        gfx.scope:
          gfx.setColor(0xa0, 0, 0x80)
          gfx.drawRectangle(x, y, boxW, boxH)

      let (floorX, floorY) = floorBody.position
      gfx.drawRectangleFill(floorX, floorY, 800.0, wallThickness)
      gfx.scope:
        gfx.setColor(0xa0, 0x80, 0)
        gfx.drawRectangle(floorX, floorY, 800.0, wallThickness)

    ui.frame:
      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: " & $tim.fps.round.toInt

main()
