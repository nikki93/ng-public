import std/json

import core

import types, triggers
import editing


# Loading / saving

proc load*(feet: var Feet, ent: Entity, node: JsonNode) =
  # Body
  if node{"dynamic"}.getBool(false):
    feet.body = phy.createDynamic(
      node{"mass"}.getFloat(1), node{"moment"}.getFloat(Inf))
  else:
    feet.body = phy.createStatic()
  feet.body.entity = ent
  if (let pos = ker.get(Position, ent); pos != nil):
    feet.body.position = (pos.x + feet.offsetX, pos.y + feet.offsetY)

  # Shape
  if (let vertsNode = node{"verts"}; vertsNode != nil):
    var verts: seq[Vec2]
    while 2 * verts.len + 1 < vertsNode.len:
      verts.add((vertsNode[2 * verts.len].getFloat(),
        vertsNode[2 * verts.len + 1].getFloat()))
    feet.shape = phy.createPoly(feet.body, verts)
  else:
    feet.shape = phy.createBox(feet.body, 40, 40)
  feet.shape.entity = ent
  feet.shape.radius = node{"radius"}.getFloat(0)

proc save*(feet: Feet, ent: Entity, node: JsonNode) =
  # Skip common defaults
  if feet.offsetX == 0:
    node.delete("offsetX")
  if feet.offsetY == 0:
    node.delete("offsetY")

  # Body
  if feet.body.kind == Dynamic:
    node["dynamic"] = %true
    node["mass"] = %feet.body.mass
    node["moment"] = %feet.body.moment

  # Shape
  node["verts"] = block:
    let verts = newJArray()
    for i in 0..<feet.shape.numVerts:
      let v = feet.shape.vert(i)
      verts.add(%v.x)
      verts.add(%v.y)
    verts
  if feet.shape.radius != 0:
    node["radius"] = %feet.shape.radius


# Editing

onEditApplyMoves.add proc() =
  for _, move, feet in ker.each(EditMove, Feet):
    let (x, y) = feet.body.position
    feet.body.position = (x + move.dx, y + move.dy)
    phy.reindex(feet.body)

onEditInput.add proc() =
  if edit.mode == "feet shape":
    var empty = true
    for ent, _, feet in ker.each(EditSelect, Feet):
      # Edit shape for selected feet
      empty = false
      if ev.touches.len == 1:
        let touch = ev.touches[0]
        if touch.pressed or touch.released:
          # Remove point near touch press, add point at touch release
          var newVerts: seq[Vec2]
          for i in 0..<feet.shape.numVerts:
            # Keep if not too close to touch
            let v = feet.shape.vert(i)
            let (wx, wy) = feet.body.toWorld(v)
            if not (abs(touch.x - wx) < 2 and abs(touch.y - wy) < 2):
              newVerts.add(v)
          if touch.released or newVerts.len == 0:
            # Add on release or if it's gonna be empty
            newVerts.add(feet.body.toLocal((touch.x, touch.y)))
          feet.shape = phy.createPoly(feet.body, newVerts)
          feet.shape.entity = ent
          if touch.released: # Save an undo point on touch release
            edit.checkpoint("edit feet shape")
    if empty:
      # No selected feet, exit mode
      edit.setMode("select")

onEditDraw.add proc() =
  if edit.mode == "feet shape":
    # Feet shape and vertices only for selected
    gfx.scope:
      gfx.setColor(0, 0, 0xff)
      for _, _, feet in ker.each(EditSelect, Feet):
        feet.body.draw()
        for i in 0..<feet.shape.numVerts:
          let (wx, wy) = feet.body.toWorld(feet.shape.vert(i))
          gfx.drawRectangleFill(wx, wy, 4, 4)

  if edit.mode == "select":
    # All feet shapes
    gfx.scope:
      gfx.setColor(0, 0, 0xff)
      for _, feet in ker.each(Feet):
        feet.body.draw()

proc inspect*(feet: var Feet, ent: Entity) =
  ui.box("info"):
    ui.text "shape: ", feet.shape.numVerts, " vertices"

    if edit.enabled and not ker.has(Player, ent):
      # Button to enter feet shape mode
      ui.button("shape", selected = edit.mode == "feet shape"):
        ui.event("click"):
          if edit.mode == "feet shape":
            edit.setMode("select")
          else:
            edit.setMode("feet shape")
