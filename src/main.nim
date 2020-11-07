import boot

import timing, graphics, events


proc sayHello(name: cstring)
  {.importc.}


proc main() =
  let testImg = gfx.loadImage("assets/player.png")
  let testEff = gfx.loadEffect("test.frag")

  when defined(emscripten):
    sayHello("person")

  ev.loop:
    tim.frame()

    gfx.frame:
      gfx.scope:
        gfx.useEffect(testEff)
        testEff.set("u_time", tim.t)
        gfx.drawImage(testImg, 100, 200, 0.4)

main()
