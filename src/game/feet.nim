import std/json

import ng

import types, triggers, editing


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

onEditDraw.add proc() =
  if edit.getMode == "select":
    gfx.scope:
      gfx.setColor(0, 0, 0xff)
      for _, feet in ker.each(Feet):
        feet.body.draw()
