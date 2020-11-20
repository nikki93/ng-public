import std/[json, os]

import ng

import types, triggers, editing


# Loading

proc load*(spr: var Sprite, ent: Entity, node: JsonNode) =
  if not node.hasKey("scale"):
    spr.scale = 0.25
  let imageNameJson = node{"imageName"}
  if imageNameJson != nil:
    spr.image = gfx.loadImage("assets/" & imageNameJson.getStr())
  else:
    spr.image = gfx.loadImage("assets/player.png")


# Drawing

onDraw.add proc() =
  # Draw sprites in depth order
  ker.isort(Sprite, proc (a, b: ptr Sprite): bool =
    a.depth < b.depth)
  for _, spr, pos in ker.each(Sprite, Position):
    gfx.drawImage(spr.image, pos.x, pos.y, spr.scale)


# Editing

onEditUpdateBoxes.add proc() =
  for ent, pos, spr in ker.each(Position, Sprite):
    let (imgW, imgH) = spr.image.size
    edit.updateBox(ent, pos.x, pos.y, spr.scale * imgW, spr.scale * imgH)

proc inspect*(spr: var Sprite, ent: Entity) =
  # Image preview
  ui.elem("img", "preview checker", src = spr.image.blobUrl)

  # Image picker
  var picking {.global.} = false
  var entries {.global.}: seq[tuple[image: Image, filename: string]]
  if not picking:
    entries.setLen 0
  ui.box("info"):
    ui.text "path: ", spr.image.path
    ui.button("pick", selected = picking):
      ui.event("click"):
        picking = true
        entries.setLen 0
        for kind, path in walkDir("assets/"):
          if kind == pcFile:
            let split = path.splitFile
            if split.ext == ".png":
              entries.add((gfx.loadImage(path), path.extractFilename))
  if picking:
    ui.box("picker-container"):
      ui.event("click"):
        picking = false
      ui.box("picker"):
        ui.box("content"):
          for entry in entries:
            ui.box("cell"):
              ui.event("click"):
                if picking:
                  spr.image = entry.image.copy
                  picking = false
              ui.box("thumbnail-container"):
                ui.elem("img", "thumbnail checker", src = entry.image.blobUrl)
              ui.box("filename"):
                ui.text(entry.filename)

  # General details
  ui.box("info"):
    let (imgW, imgH) = spr.image.size
    ui.text "width: ", imgW, ", height: ", imgH
