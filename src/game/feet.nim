import std/json

import ng

import types, triggers
import editing


# Loading

proc load*(feet: var Feet, ent: Entity, node: JsonNode) =
  feet.body = phy.createStatic()
  feet.body.entity = ent
  let pos = ker.get(Position, ent)
  if pos != nil:
    feet.body.position = (pos.x, pos.y)

  let vertsJson = node{"verts"}
  if vertsJson != nil:
    var verts: seq[Vec2]
    while 2 * verts.len + 1 < vertsJson.len:
      verts.add((vertsJson[2 * verts.len].getFloat(),
        vertsJson[2 * verts.len + 1].getFloat()))
    feet.shape = phy.createPoly(feet.body, verts)
  else:
    feet.shape = phy.createBox(feet.body, 40, 40)
  feet.shape.entity = ent


# Editing

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

    if edit.enabled and ker.get(Player, ent) == nil:
      # Button to enter feet shape mode
      ui.button("feet shape", selected = edit.mode == "feet shape"):
        ui.event("click"):
          if edit.mode == "feet shape":
            edit.setMode("select")
          else:
            edit.setMode("feet shape")
