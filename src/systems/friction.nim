import std/json

import core

import types


proc load*(fric: var Friction, ent: Entity, node: JsonNode) =
  let feet = ker.get(Feet, ent)
  if feet != nil:
    fric.constr = phy.createPivot(phy.background, feet.body)
    fric.constr.maxForce = 800
    fric.constr.maxBias = 0
    echo "friction loaded!"
