import std/math

import boot

import timing, graphics, events, uis


proc main() =
  let testImg = gfx.loadImage("assets/player.png")
  let testEff = gfx.loadEffect("test.frag")

  var (x, y) = (100.0, 100.0)

  ev.loop:
    tim.frame()

    if not ev.windowFocused:
      return

    if ev.touches.len == 1:
      let touch = ev.touches[0]
      (x, y) = (touch.x, touch.y)

    gfx.frame:
      gfx.scope:
        gfx.useEffect(testEff)
        testEff.set("u_time", tim.t)
        gfx.drawImage(testImg, 100, 200, 0.4)

      gfx.scope:
        gfx.setColor(0xff, 0, 0xff)
        gfx.drawRectangle(x, y, 80, 80)

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
              ui.text $x & ", " & $y

      ui.patch("bottom"):
        ui.box("status"):
          ui.box:
            ui.text "fps: " & $tim.fps.round.toInt

main()
