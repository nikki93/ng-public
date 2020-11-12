import std/[math, random]

import boot

import timing, graphics, events, uis, physics, kernel


type
  Box = object
    body: Body
    shape: Shape


proc main() =
  const (screenW, screenH) = (800.0, 450.0)

  phy.gravity = (0.0, 9.8 * 64)

  let wallThickness = 40.0

  let floorBody = phy.createStatic()
  floorBody.position = (0.5 * screenW, 450.0 - 0.5 * wallThickness)
  let floorShape = phy.createBox(floorBody, screenW, wallThickness)

  let leftWallBody = phy.createStatic()
  leftWallBody.position = (0.5 * wallThickness, 0.5 * screenH)
  let leftWallShape = phy.createBox(leftWallBody, wallThickness, screenH)

  let rightWallBody = phy.createStatic()
  rightWallBody.position = (screenW - 0.5 * wallThickness, 0.5 * screenH)
  let rightWallShape = phy.createBox(rightWallBody, wallThickness, screenH)

  const (boxW, boxH) = (40.0, 40.0)
  for i in 1..50:
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

    proc removeTouchedBoxes() = # Need to wrap in a proc bc. of `ev.loop` :|
      if ev.touches.len == 1:
        let touch = ev.touches[0]
        var count = 0
        phy.segmentQuery((touch.x, touch.y), (touch.x, touch.y + 1), 0,
          proc(res: SegmentQueryResult) =
            if res.ent != null:
              inc count
              ker.remove(Box, res.ent)
              ker.destroy(res.ent))
        if count > 0:
          echo "destroyed ", count, ", boxes"
    removeTouchedBoxes()

    phy.frame()

    gfx.frame:
      for _, box in ker.each(Box):
        let (x, y) = box.body.position
        gfx.drawRectangleFill(x, y, boxW, boxH)

      let (floorX, floorY) = floorBody.position
      gfx.drawRectangleFill(floorX, floorY, 800.0, wallThickness)

      let (leftWallX, leftWallY) = leftWallBody.position
      gfx.drawRectangleFill(leftWallX, leftWallY, wallThickness, screenH)

      let (rightWallX, rightWallY) = rightWallBody.position
      gfx.drawRectangleFill(rightWallX, rightWallY, wallThickness, screenH)

    ui.frame:
      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: " & $tim.fps.round.toInt

  ker.clear(Box)

main()
