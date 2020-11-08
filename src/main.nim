import boot

import timing, graphics, events, uis


proc main() =
  let testImg = gfx.loadImage("assets/player.png")
  let testEff = gfx.loadEffect("test.frag")

  ev.loop:
    tim.frame()

    if not ev.windowFocused:
      return

    gfx.frame:
      gfx.scope:
        gfx.useEffect(testEff)
        testEff.set("u_time", tim.t)
        gfx.drawImage(testImg, 100, 200, 0.4)

      gfx.scope:
        gfx.setColor(0xff, 0, 0xff)
        gfx.drawRectangle(300, 200, 80, 80)

    ui.patch "top":
      ui.elem "div", { "class": "toolbar" }:
        ui.elem "button", {
          "class": "play"
        }:
          discard

    ui.patch "side":
      ui.elem "div", { "class": "inspector" }:
        ui.elem "details", { "open": "" }:
          ui.elem "summary":
            ui.text "position"
          ui.elem "div", { "class": "info" }:
            ui.text "100, 200"

    ui.patch "bottom":
      ui.elem "div", { "class": "status" }:
        ui.elem "div":
          ui.text "bottom!"

main()
