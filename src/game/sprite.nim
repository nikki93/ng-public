import all


# Loading

proc load*(spr: var Sprite, ent: Entity, node: JsonNode) =
  spr.image = gfx.loadImage("assets/" & node["imageName"].getStr())


# Drawing

onDraw.add proc() =
  # Draw sprites in depth order
  ker.isort(Sprite, proc (a, b: ptr Sprite): bool {.cdecl.} =
    a.depth < b.depth)
  for _, spr, pos in ker.each(Sprite, Position):
    gfx.drawImage(spr.image, pos.x, pos.y, spr.scale)
