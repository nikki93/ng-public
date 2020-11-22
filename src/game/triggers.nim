## Triggers are used to track a bunch of procs to execute at once on some
## event or phase of game processing.

type
  Trigger* = object
    procs: seq[proc() {.nimcall.}]

proc add*(trig: var Trigger, p: proc() {.nimcall.}) =
  trig.procs.add(p)

proc run*(trig: Trigger) =
  for p in trig.procs:
    p()



# Physics

var onPhysicsPre*: Trigger
var onPhysicsPost*: Trigger


# Draw

var onApplyView*: Trigger
var onDraw*: Trigger
var onDrawOverlay*: Trigger


# Edit

var onEditUpdateBoxes*: Trigger
var onEditApplyMoves*: Trigger
var onEditInput*: Trigger
var onEditDraw*: Trigger
