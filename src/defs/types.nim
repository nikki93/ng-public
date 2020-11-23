## Defines all of the types that can be added to entities in the game.
##
## These are in one file so the game's state structure is understandable
## at a glance, and for easy import into other modules.

import std/hashes

import ng


template nosave() {.pragma.} # Skip save / load for type

template noedit() {.pragma.} # Skip display of type in editor UI


type
  # Basics

  Position* {.comp.} = object
    x*, y*: float

  Sprite* {.comp.} = object
    image*: Image
    depth*: float
    scale*: float

    col*, row*: int
    cols*, rows*: int

    flipH*: bool


  # Animation

  AnimationClip* = object
    name*: string
    start*, count*: int
    fps*: float
    pause*: float

  Animation* {.comp.} = object
    clips*: seq[AnimationClip]
    clipNameHashes*: seq[Hash]
    clipIndex*: int
    time*: float


  # Solids

  Feet* {.comp.} = object
    body*: Body
    shape*: Shape

    offsetX*, offsetY*: float


  # Motion

  Walk* {.comp, nosave.} = object
    target*: Body
    constr*: Constraint

    touchTime*: float

  Friction* {.comp.} = object
    constr*: Constraint


  # View

  ViewFollow* {.comp.} = object
    x*, y*: float

    offsetX*, offsetY*: float
    border*: float
    rate*: float

  WorldBounds* {.comp.} = object
    minX*, maxX*, minY*, maxY*: float

    bodies*: array[4, Body]
    shapes*: array[4, Shape]


  # Player

  Player* {.comp.} = object


  # Edit

  EditSelect* {.comp, nosave, noedit.} = object

  EditBox* {.comp, nosave, noedit.} = object
    x*, y*: float
    width*, height*: float
