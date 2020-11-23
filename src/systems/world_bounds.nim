import std/json

import core

import types


proc load*(wb: var WorldBounds, ent: Entity, node: JsonNode) =
  if wb.maxX > wb.minX and wb.maxY > wb.minY:
    let thick = 100.0

    wb.bodies[0] = phy.createStatic() # Left
    wb.bodies[0].position = (wb.minX - 0.5 * thick, 0.5 * (wb.minY + wb.maxY))
    wb.bodies[1] = phy.createStatic() # Right
    wb.bodies[1].position = (wb.maxX + 0.5 * thick, 0.5 * (wb.minY + wb.maxY))
    wb.bodies[2] = phy.createStatic() # Top
    wb.bodies[2].position = (0.5 * (wb.minX + wb.maxX), wb.minY - 0.5 * thick)
    wb.bodies[3] = phy.createStatic() # Bottom
    wb.bodies[3].position = (0.5 * (wb.minX + wb.maxX), wb.maxY + 0.5 * thick)

    wb.shapes[0] = phy.createBox( # Left
      wb.bodies[0], thick, wb.maxY - wb.minY + 2 * thick)
    wb.shapes[1] = phy.createBox( # Right
      wb.bodies[1], thick, wb.maxY - wb.minY + 2 * thick)
    wb.shapes[2] = phy.createBox( # Top
      wb.bodies[2], wb.maxX - wb.minX + 2 * thick, thick)
    wb.shapes[3] = phy.createBox( # Bottom
      wb.bodies[3], wb.maxX - wb.minX + 2 * thick, thick)
