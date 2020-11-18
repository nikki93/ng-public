import ng

import types


type
  Edit = object
    enabled: bool
    mode: string
    
    viewX, viewY: float
    viewWidth, viewHeight: float


# Singleton

var edit*: Edit


# Mode

proc isEnabled*(edit: Edit): bool {.inline.} =
  edit.enabled

proc play*(edit: var Edit) =
  edit.enabled = false

proc stop*(edit: var Edit) =
  edit.enabled = true
  edit.mode = "select"


# Boxes

proc updateBox*(edit: var Edit, ent: Entity, x, y, width, height: float)
  {.inline.} =
  var box = ker.get(EditBox, ent)
  if box != nil:
    # Merge with existing box
    let minX = min(box.x - 0.5 * box.width, x - 0.5 * width)
    let minY = min(box.y - 0.5 * box.height, y - 0.5 * height)
    let maxX = max(box.x + 0.5 * box.width, x + 0.5 * width)
    let maxY = max(box.y + 0.5 * box.height, y + 0.5 * height)
    box.x = 0.5 * (minX + maxX)
    box.y = 0.5 * (minY + maxY)
    box.width = maxX - minX
    box.height = maxY - minY
  else:
    # New box
    box = ker.add(EditBox, ent)
    (box.x, box.y, box.width, box.height) = (x, y, width, height)


import all # Keep above exports above this so type-specific
           # hooks can use them


# Draw

proc applyView*(edit: var Edit) =
  gfx.setView(edit.viewX, edit.viewY, edit.viewWidth, edit.viewHeight)

proc draw*(edit: var Edit) =
  if edit.mode == "select":
    # Red boxes for unselected
    gfx.scope:
      gfx.setColor(0xff, 0, 0)
      for _, box in ker.each(EditBox):
        gfx.drawRectangle(box.x, box.y, box.width, box.height)

  if edit.mode == "select" or edit.mode == "move":
    discard

  onEditDraw.run()


# UI

proc toolbar*(edit: var Edit) =
  # Play / stop
  ui.button(class = if edit.enabled: "play" else: "stop"):
    ui.event("click"):
      if edit.enabled:
        edit.play()
      else:
        edit.stop()

proc status*(edit: var Edit) =
  discard

proc inspector*(edit: var Edit) =
  discard


# Frame

proc input(edit: var Edit) =
  discard

proc frame*(edit: var Edit) =
  edit.input()

  # Update boxes
  ker.clear(EditBox)
  onEditUpdateBoxes.run()


# Init / deinit

proc init(edit: var Edit) =
  # Initial state
  edit.mode = "select"
  (edit.viewX, edit.viewY) = (400.0, 225.0)
  (edit.viewWidth, edit.viewHeight) = (800.0, 450.0)

edit.init()
