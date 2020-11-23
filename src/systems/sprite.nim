import std/[json, os]

import core

import types, triggers
import editing


# Loading / saving

proc load*(spr: var Sprite, ent: Entity, node: JsonNode) =
  # Non-zero defaults
  if not node.hasKey("scale"):
    spr.scale = 0.25
  if not node.hasKey("cols"):
    spr.cols = 1
  if not node.hasKey("rows"):
    spr.rows = 1

  # Load image, with default fallback
  let imageNameNode = node{"imageName"}
  if imageNameNode != nil:
    spr.image = gfx.loadImage("assets/" & imageNameNode.getStr())
  else:
    spr.image = gfx.loadImage("assets/player.png")

proc save*(spr: Sprite, ent: Entity, node: JsonNode) =
  # Skip common defaults
  if spr.col == 0:
    node.delete("col")
  if spr.row == 0:
    node.delete("row")
  if spr.cols <= 1:
    node.delete("cols")
  if spr.rows <= 1:
    node.delete("rows")
  if not spr.flipH:
    node.delete("flipH")

  # Image name
  node["imageName"] = %spr.image.path.extractFilename


# Drawing

onDraw.add proc() =
  # Draw sprites in depth order
  ker.isort(Sprite, proc (a, b: ptr Sprite): bool =
    a.depth < b.depth)
  for _, spr, pos in ker.each(Sprite, Position):
    if spr.rows <= 1 and spr.cols <= 1: # Whole image
      gfx.drawImage(spr.image, pos.x, pos.y,
        scale = spr.scale, flipH = spr.flipH)
    else: # Sub-image
      let (imgW, imgH) = spr.image.size
      let (subW, subH) = (imgW / spr.cols.toFloat, imgH / spr.rows.toFloat)
      let (subX, subY) = (spr.col.toFloat * subW, spr.row.toFloat * subH)
      gfx.drawImage(spr.image, pos.x, pos.y,
        scale = spr.scale, flipH = spr.flipH,
        subX = subX, subY = subY, subW = subW, subH = subH)


# Editing

onEditUpdateBoxes.add proc() =
  for ent, pos, spr in ker.each(Position, Sprite):
    let (imgW, imgH) = spr.image.size
    let w = spr.scale * imgW / spr.cols.toFloat
    let h = spr.scale * imgH / spr.rows.toFloat
    edit.updateBox(ent, pos.x, pos.y, w, h)

proc inspect*(spr: var Sprite, ent: Entity) =
  # Image preview
  ui.elem("img", "preview checker", src = spr.image.blobUrl)

  # Image picker
  var picking {.global.} = false
  var entries {.global.}: seq[Image]
  if not picking:
    entries.setLen 0
  ui.box("info"):
    ui.text "path: ", spr.image.path
    ui.button("pick", selected = picking):
      ui.event("click"): # On click, enable picker and populate entries
        picking = true
        entries.setLen 0
        for kind, path in walkDir("assets/"):
          if kind == pcFile:
            let split = path.splitFile
            if split.ext == ".png":
              entries.add(gfx.loadImage(path))
  if picking:
    ui.box("picker-container"): # Darkened background overlay
      ui.event("click"): # Dismiss if background clicked
        picking = false
      ui.box("picker"): # Popup container
        ui.box("content"): # Scroll view
          for entry in entries:
            ui.box("cell"): # Clickable cell per image
              ui.event("click"):
                if picking:
                  spr.image = entry.copy
                  picking = false
                  edit.checkpoint("change image")
              ui.box("thumbnail-container"):
                ui.elem("img", "thumbnail checker", src = entry.blobUrl)
              ui.box("filename"):
                ui.text(entry.path.extractFilename)

  # General details
  ui.box("info"):
    let (imgW, imgH) = spr.image.size
    ui.text "width: ", imgW, ", height: ", imgH
