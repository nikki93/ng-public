import std/math

import ng

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

onApplyView.add proc() =
  for _, vf in ker.each(ViewFollow):
    gfx.setView(vf.x, vf.y, width, height)
    break
