import utils


const cpH = "\"precomp.h\""

type
  cpSpace {.importc: "cpSpace", header: cpH.} = object

  Physics = object
    space: ptr cpSpace


# Init / deinit

proc init(phy: var Physics) =
  # Init Chipmunk space
  proc cpSpaceNew(): ptr cpSpace
    {.importc, header: cpH.}
  phy.space = cpSpaceNew()

  echo "initialized physics"

proc `=destroy`(phy: var Physics) =
  # Destroy Chipmunk space
  if phy.space != nil:
    proc cpSpaceFree(space: ptr cpSpace)
      {.importc, header: cpH.}
    cpSpaceFree(phy.space)

  destroyFields(phy)
  echo "deinitialized physics"


# Singleton

proc `=copy`(a: var Physics, b: Physics) {.error.}

var phy*: Physics
phy.init()
