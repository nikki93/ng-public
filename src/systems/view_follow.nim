import std/math

import core

import types, triggers


const (width, height) = (800.0, 450.0)


onPhysicsPost.add proc() =
  for _, vf, pos in ker.each(ViewFollow, Position):
    # Delta to target from center
    let (dx, dy) = (pos.x + vf.offsetX - vf.x, pos.y + vf.offsetY - vf.y)

    # Move along delta with smoothing
    if abs(dx) > 0.5 * width - vf.border:
      vf.x += pow(2, -vf.rate * tim.dt) * # Smoothing factor
        abs(dx) / dx * # Sign of delta
        (abs(dx) - (0.5 * width - vf.border))
    if abs(dy) > 0.5 * height - vf.border:
      vf.y += pow(2, -vf.rate * tim.dt) * # Smoothing factor
        abs(dy) / dy * # Sign of delta
        (abs(dy) - (0.5 * height - vf.border))

    # Stay in world bounds
    for _, wb in ker.each(WorldBounds):
      if vf.x - 0.5 * width < wb.minX:
        vf.x = wb.minX + 0.5 * width
      if vf.x + 0.5 * width > wb.maxX:
        vf.x = wb.maxX - 0.5 * width
      if vf.y - 0.5 * height < wb.minY:
        vf.y = wb.minY + 0.5 * height
      if vf.y + 0.5 * height > wb.maxY:
        vf.y = wb.maxY - 0.5 * height
      break # Disambiguate by picking first one

onApplyView.add proc() =
  for _, vf in ker.each(ViewFollow):
    gfx.setView(vf.x, vf.y, width, height)
    break # Disambiguate by picking first one
