## Defines all of the types that can be added to entities in the game.
##
## These are in one file so the game's state structure is understandable
## at a glance, and for easy import into other modules.

import ng


template nosave() {.pragma.} # Skip save / load for type

template noedit() {.pragma.} # Skip display of type in editor UI


type
  # Basics

  Position* {.ng.} = object
    x*, y*: float

  Sprite* {.ng.} = object
    image*: Image
    depth*: float
    scale*: float

    col*, row*: int
    cols*, rows*: int

    flipH*: bool


  # Solids

  Feet* {.ng.} = object
    body*: Body
    shape*: Shape

    offsetX*, offsetY*: float


  # Motion

  Walk* {.ng, nosave.} = object
    target*: Body
    constr*: Constraint

    touchTime*: float

  Friction* {.ng.} = object
    constr*: Constraint


  # View

  ViewFollow* {.ng.} = object
    x*, y*: float

    offsetX*, offsetY*: float
    border*: float
    rate*: float

  WorldBounds* {.ng.} = object
    minX*, maxX*, minY*, maxY*: float

    bodies*: array[4, Body]
    shapes*: array[4, Shape]


  # Player

  Player* {.ng.} = object


  # Edit

  EditSelect* {.ng, nosave, noedit.} = object

  EditBox* {.ng, nosave, noedit.} = object
    x*, y*: float
    width*, height*: float
