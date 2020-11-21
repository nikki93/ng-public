## Implements the in-game scene editor. The UI implementation depends on
## type-specific hooks (`load`, `inspect`, ...), but type-specific hooks
## depend on parts of the editing API (`updateBox`, ...), so the UI
## implementation is in a separate 'editing_ui' file.

import std/algorithm

import ng

import types, triggers


type
  Edit* = object
    enabled: bool
    mode: string

    viewX, viewY: float
    viewWidth, viewHeight: float


# Singleton

proc `=copy`(a: var Edit, b: Edit) {.error.}

var edit*: Edit


# Mode

proc isEnabled*(edit: Edit): bool {.inline.} =
  edit.enabled

proc play*(edit: var Edit) =
  edit.enabled = false

proc stop*(edit: var Edit) =
  edit.enabled = true
  edit.mode = "select"

proc getMode*(edit: Edit): lent string {.inline.} =
  edit.mode

proc setMode*(edit: var Edit, mode: string) =
  edit.mode = mode


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
    # Doubled green boxes for selected
    gfx.scope:
      let (vx, vy, vw, vh) = gfx.view
      gfx.setColor(0, 0x80, 0x40)
      for _, _, box in ker.each(EditSelect, EditBox):
        var (x, y, w, h) = (box.x, box.y, box.width, box.height)
        if x - 0.5 * w <= vx - 0.5 * vw and x + 0.5 * w >= vx + 0.5 * vw and
          y - 0.5 * h <= vy - 0.5 * vh and y + 0.5 * h >= vy + 0.5 * vh:
          # Covers entire view, just draw at boundary
          (x, y, w, h) = (vx, vy, vw - 4, vh - 4)
        gfx.drawRectangle(x, y, w, h)
        gfx.drawRectangle(x, y, w + 4, h + 4)

  onEditDraw.run()


# Frame

proc input(edit: var Edit) =
  onEditInput.run()

  if edit.mode == "select":
    # Touch-to-select
    if ev.touches.len == 1 and ev.touches[0].pressed:
      # Collect hits in ascending area order
      let (tx, ty) = (ev.touches[0].x, ev.touches[0].y)
      var hits: seq[(float, Entity)]
      for ent, box in ker.each(EditBox):
        if abs(tx - box.x) < 0.5 * box.width and
          abs(ty - box.y) < 0.5 * box.height:
          hits.add((box.width * box.height, ent))
      hits.sort()

      # Pick after current selection, or first if none
      var pick = nullEntity
      var pickNext = true
      for (_, ent) in hits:
        if ker.get(EditSelect, ent) != nil:
          pickNext = true
        elif pickNext:
          pick = ent
          pickNext = false
      ker.clear(EditSelect)
      if pick != nullEntity:
        discard ker.add(EditSelect, pick)

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
