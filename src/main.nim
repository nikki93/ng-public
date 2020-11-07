import boot

import timing, graphics, events


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

main()
