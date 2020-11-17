import all


# Loading

proc load*(feet: var Feet, ent: Entity, node: JsonNode) =
  feet.body = phy.createStatic()
  feet.body.entity = ent
  let pos = ker.get(Position, ent)
  if pos != nil:
    feet.body.position = (pos.x, pos.y)

  var verts: seq[Vec2]
  let vertsJson = node["verts"]
  while 2 * verts.len + 1 < vertsJson.len:
    verts.add((vertsJson[2 * verts.len].getFloat(),
      vertsJson[2 * verts.len + 1].getFloat()))
  feet.shape = phy.createPoly(feet.body, verts)
  feet.shape.entity = ent
