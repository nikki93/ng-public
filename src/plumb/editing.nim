## Implements the in-game scene editor. The inspector UI is in a separate file
## for reasons explained at the top of that file.

import std/[algorithm, json, deques]

import core

import types, triggers
import saveload


type
  Action = object
    description: string ## What the user did (eg. "move entity")
    node: JsonNode      ## Saved state after action

  Edit* = object
    enabled: bool
    mode: string

    viewX, viewY: float
    viewWidth, viewHeight: float

    undos: Deque[Action]
    redos: Deque[Action]


# Singleton

proc `=copy`(a: var Edit, b: Edit) {.error.}

var edit*: Edit


# Mode

proc enabled*(edit: Edit): bool {.inline.} =
  edit.enabled

proc play*(edit: var Edit) =
  edit.enabled = false

proc restore(edit: var Edit)

proc stop*(edit: var Edit) =
  edit.enabled = true
  edit.restore()
  edit.mode = "select"

proc mode*(edit: Edit): lent string {.inline.} =
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


# Undo / redo

proc checkpoint*(edit: var Edit, description: string) =
  # Save an undo action with the scene data. Also keep track of which
  # entities were selected at the time.
  let node = saveScene(
    extra = proc(ent: Entity, node: JsonNode) =
    if ker.get(EditSelect, ent) != nil:
      node["selected"] = %true)
  edit.undos.addLast(Action(description: description, node: node))
  while edit.undos.len > 50: # Limit undo buffer size
    edit.undos.popFirst()
  edit.redos.clear()

proc clearActions*(edit: var Edit) =
  edit.undos.clear()
  edit.redos.clear()

proc restore(edit: var Edit) =
  # Restore into kernel from last action in undo history. Also restore the
  # selection state.
  if edit.undos.len > 0:
    ker.clear()
    loadScene(edit.undos[^1].node,
      extra = proc(ent: Entity, node: JsonNode) =
      if node{"selected"}.getBool(false):
        discard ker.add(EditSelect, ent))

proc swapAction(src: var Deque[Action], dest: var Deque[Action]) =
  dest.addLast(src.popLast())
  edit.restore()

proc undo*(edit: var Edit) =
  if edit.undos.len > 1:
    swapAction(src = edit.undos, dest = edit.redos)
    echo "undid: ", edit.redos[^1].description

proc redo*(edit: var Edit) =
  if edit.redos.len > 0:
    swapAction(src = edit.redos, dest = edit.undos)
    echo "redid: ", edit.undos[^1].description


# Non-inspector UI

proc toolbar*(edit: var Edit) =
  # Play / stop
  ui.button(class = if edit.enabled: "play" else: "stop"):
    ui.event("click"):
      if edit.enabled:
        edit.play()
      else:
        edit.stop()

  ui.box("flex-gap")

  if edit.enabled:
    # Undo / redo
    ui.button("undo", disabled = edit.undos.len <= 1):
      ui.event("click"):
        edit.undo()
    ui.button("redo", disabled = edit.redos.len == 0):
      ui.event("click"):
        edit.redo()

    ui.box("small-gap")

    # Pan
    ui.button("pan", selected = edit.mode == "view pan"):
      ui.event("click"):
        edit.setMode(if edit.mode == "view pan": "select" else: "view pan")

    # Zoom
    ui.button("zoom-in"):
      ui.event("click"):
        edit.viewWidth *= 0.5
        edit.viewHeight *= 0.5
    ui.button("zoom-out"):
      ui.event("click"):
        edit.viewWidth *= 2
        edit.viewHeight *= 2

proc status*(edit: var Edit) =
  if edit.enabled:
    ui.box: # Zoom level
      ui.text edit.viewWidth / 800, "x"

    ui.box("small-gap")

    ui.box: # Mode
      ui.text edit.mode


# Input

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

  if edit.mode == "view pan":
    # Pan view by dragging
    if ev.touches.len == 1:
      let touch = ev.touches[0]
      let (zx, zy) = gfx.viewToWorld(0, 0)
      let (dx, dy) = gfx.viewToWorld(touch.screenDX, touch.screenDY)
      edit.viewX -= dx - zx
      edit.viewY -= dy - zy


# Frame

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

  # Reserve undo / redo buffer
  edit.undos = initDeque[Action](50)
  edit.redos = initDeque[Action](50)

edit.init()
