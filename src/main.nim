import std/[math, random]

import boot

import timing, graphics, events, kernel


type
  Depth = object
    depth: float

  Position = object
    x, y: float

  Oscillate = object
    xRate, yRate: float
    xPhase, yPhase: float
    xAmp, yAmp: float

  Size = object
    width, height: float

  Color = object
    r, g, b: uint8


proc main() =
  let playerImg = gfx.loadImage("assets/player.png")

  randomize()

  for i in 1..3000:
    let ent = ker.create()

    var depth = ker.add(Depth, ent)
    depth.depth = i.toFloat

    var pos = ker.add(Position, ent)
    pos.x = rand(800.0)
    pos.y = rand(450.0)

    var size = ker.add(Size, ent)
    size.width = rand(10.0..200.0)
    size.height = rand(10.0..200.0)

    var col = ker.add(Color, ent)
    col.r = cast[uint8](rand(0x20..0xa0))
    col.g = cast[uint8](rand(0x20..0xa0))
    col.b = cast[uint8](rand(0x20..0xa0))

    if i mod 2 == 0:
      var osc = ker.add(Oscillate, ent)
      osc.xRate = rand(0.2..5.0)
      osc.xPhase = rand(0.0..(2 * PI))
      osc.xAmp = rand(20.0..300.0)

  ev.loop:
    tim.frame()

    for _, osc, pos in ker.each(Oscillate, Position):
      pos.x += osc.xAmp * sin(osc.xRate * tim.t + osc.xPhase) * tim.dt
      pos.y += osc.yAmp * sin(osc.yRate * tim.t + osc.yPhase) * tim.dt

    if ev.touches.len > 0:
      for ent, size, pos in ker.each(Size, Position):
        for touch in ev.touches:
          if abs(touch.x - pos.x) < 0.5 * size.width and
            abs(touch.y - pos.y) < 0.5 * size.height:
            ker.destroy(ent)
            break

    gfx.frame:
      ker.isort(Depth, proc (a, b: auto): auto {.cdecl.} =
        a.depth < b.depth)
      for _, _, pos, size, col in ker.each(Depth, Position, Size, Color):
        gfx.scope:
          gfx.setColor(col.r, col.g, col.b)
          gfx.drawRectangleFill(pos.x, pos.y, size.width, size.height)

      gfx.drawImage(playerImg, 100, 100, 0.25)

  ker.clear(Depth)
  ker.clear(Position)
  ker.clear(Oscillate)
  ker.clear(Size)
  ker.clear(Color)

main()
