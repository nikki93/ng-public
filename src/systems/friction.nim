import std/json

import core

import types


# Loading

proc load*(fric: var Friction, ent: Entity, node: JsonNode) =
  if (let feet = ker.get(Feet, ent); feet != nil):
    fric.constr = phy.createPivot(phy.background, feet.body)
    fric.constr.maxForce = 800
    fric.constr.maxBias = 0
    echo "friction loaded!"
