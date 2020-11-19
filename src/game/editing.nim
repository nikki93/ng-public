import std/[algorithm, strutils, macros]

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

func titleify(title: string): string =
  ## Turn "TitlesYay" into "titles yay"
  for i, c in title:
    if c.isUpperAscii:
      if i > 0:
        result.add(" ")
      result.add(c.toLowerAscii)
    else:
      result.add(c)

proc inspector*(edit: var Edit) =
  # Inspectors for selected entities
  for ent, _ in ker.each(EditSelect):
    ui.box("inspector"):
      # Section for each type that isn't marked `{.noedit.}`
      forEachRegisteredTypeSkip(T, "noedit"):
        let inst = ker.get(T, ent)
        if inst != nil:
          const title = titleify($T)
          ui.elem("details", class = title, key = title, open = true):
            # Header with title and remove button
            ui.elem("summary"):
              ui.text(title)
              ui.button("remove"):
                ui.event("click"):
                  discard # TODO(nikki): Removing types
            
            # TODO(nikki): Custom inspect

            # Simple fields
            for name, value in fieldPairs(inst[]):
              when value is SomeFloat:
                ui.box("info"):
                  let valueStr = value.formatFloat(ffDecimal, precision = 2)
                  ui.text(name & ": " & valueStr)

      # TODO(nikki): Adding types


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
      var pick = null
      var pickNext = true
      for (_, ent) in hits:
        if ker.get(EditSelect, ent) != nil:
          pickNext = true
        elif pickNext:
          pick = ent
          pickNext = false
      ker.clear(EditSelect)
      if pick != null:
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
