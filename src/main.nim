import std/[math, random]

import ng



# Types

type
  Position {.ng.} = object
    x, y: float

  Sprite {.ng.} = object
    image: Image
    #col, row: int
    #cols, rows: int
    scale: float
    depth: float
    #flipH: bool


# Triggers

type Trigger = seq[proc()]

proc run(s: Trigger) =
  for fn in s:
    fn()

var onDraw: Trigger


# Sprite

onDraw.add proc() =
  ker.isort(Sprite, proc (a, b: ptr Sprite): bool {.cdecl.} =
    a.depth < b.depth)
  for _, spr, pos in ker.each(Sprite, Position):
    gfx.drawImage(spr.image, pos.x, pos.y, spr.scale)


# main

proc main() =
  initMeta()

  block:
    let ent = ker.create()

    let pos = ker.add(Position, ent)
    (pos.x, pos.y) = (100.0, 100.0)

    let spr = ker.add(Sprite, ent)
    spr.image = gfx.loadImage("assets/player.png")
    spr.scale = 0.25
    spr.depth = 1000

  ev.loop:
    tim.frame()
    if tim.dt >= 3 * 1 / 60.0: # Frame drop
      return

    if not ev.windowFocused:
      return

    phy.frame()

    gfx.frame:
      onDraw.run()

    ui.frame:
      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: " & $tim.fps.round.toInt

main()
