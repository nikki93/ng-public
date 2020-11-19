import ng


# Pragmas

template nosave() {.pragma.} # Don't save / load this type

template noedit() {.pragma.} # Don't display this type in the editor UI


## All of the types that can be added to entities in the game.

type
  # Basics

  Position* {.ng.} = object
    x*, y*: float

  Sprite* {.ng.} = object
    image*: Image
    #col*, row*: int
    #cols*, rows*: int
    scale*: float
    depth*: float
    #flipH: bool


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


  # Player

  Player* {.ng.} = object


  # Edit

  EditSelect* {.ng, nosave, noedit.} = object

  EditBox* {.ng, nosave, noedit.} = object
    x*, y*: float
    width*, height*: float
