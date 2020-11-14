## Re-exports all engine symbols. Handles module initialization and
## deinitialization in the correct order. This is the module to import when
## using the engine from application or game code.

import timing, graphics, events, physics, uis, kernel
export timing, graphics, events, physics, uis, kernel


# We use a destructor on a global variable to listen for program shutdown.

type
  DeinitHook = object

tim.init()
gfx.init()
ev.init() # Depends on window initialization by graphics
phy.init()
ui.init()
ker.init() # Deinit first since entities hold resources from other modules

proc `=destroy`(dh: var DeinitHook) =
  ker.deinit()
  ui.deinit()
  phy.deinit()
  ev.deinit()
  gfx.deinit()
  tim.deinit()

var dh {.used.}: DeinitHook
