import timing, utils


const cpH = "\"precomp.h\""

type
  cpSpace {.importc: "cpSpace", header: cpH.} = object

  cpBody {.importc: "cpBody", header: cpH.} = object
    space: ptr cpSpace

  cpConstraint {.importc: "cpConstraint", header: cpH.} = object
    space: ptr cpSpace

  cpShape {.importc: "cpShape", header: cpH.} = object
    space: ptr cpSpace

  cpVect* {.importc: "cpVect", header: cpH.} = object
    x, y: float

  Physics = object
    space: ptr cpSpace

  Vec2* = tuple
    x, y: float


# `cpVect` <-> `Vec2`

converter toVec2*(value: cpVect): Vec2 {.inline.} =
  result.x = value.x
  result.y = value.y

converter toCpVect*(value: Vec2): cpVect {.inline.} =
  result.x = value.x
  result.y = value.y


# Reused C procs

proc cpSpaceRemoveConstraint(space: ptr cpSpace, constr: ptr cpConstraint)
  {.importc, header: cpH.}

proc cpSpaceRemoveShape(space: ptr cpSpace, shape: ptr cpShape)
  {.importc, header: cpH.}


# Body wrapper

type
  Body* = object
    cp: ptr cpBody

proc `=copy`(a: var Body, b: Body) {.error.}

proc `=destroy`(body: var Body) =
  if body.cp != nil:
    # Remove attached constraints and shapes. This must be done before
    # freeing the shape (see note at:
    # http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#cpBody-Memory)
    proc cpBodyEachConstraint(
      body: ptr cpBody,
      fn: proc(body: ptr cpBody, constr: ptr cpConstraint, data: pointer)
        {.cdecl.},
      data: pointer)
      {.importc, header: cpH.}
    cpBodyEachConstraint(
      body.cp,
      proc(body: ptr cpBody, constr: ptr cpConstraint, data: pointer)
        {.cdecl.} =
      cpSpaceRemoveConstraint(constr.space, constr),
      nil)
    proc cpBodyEachShape(
      body: ptr cpBody,
      fn: proc(body: ptr cpBody, shape: ptr cpShape, data: pointer)
        {.cdecl.},
      data: pointer)
      {.importc, header: cpH.}
    cpBodyEachShape(
      body.cp,
      proc(body: ptr cpBody, shape: ptr cpShape, data: pointer)
        {.cdecl.} =
      cpSpaceRemoveShape(shape.space, shape),
      nil)

    # Remove body from space and free it
    proc cpSpaceRemoveBody(space: ptr cpSpace, body: ptr cpBody)
      {.importc, header: cpH.}
    cpSpaceRemoveBody(body.cp.space, body.cp)
    proc cpBodyFree(body: ptr cpBody)
      {.importc, header: cpH.}
    cpBodyFree(body.cp)

proc initBody(cp: ptr cpBody): Body =
  Body(cp: cp)

proc position*(body: Body): Vec2 {.inline.} =
  proc cpBodyGetPosition(body: ptr cpBody): cpVect
    {.importc, header: cpH.}
  cpBodyGetPosition(body.cp)

proc `position=`*(body: Body, value: Vec2) {.inline.} =
  proc cpBodySetPosition(body: ptr cpBody, value: cpVect)
    {.importc, header: cpH.}
  cpBodySetPosition(body.cp, value)


# Constraint wrapper

type
  Constraint* = object
    cp: ptr cpConstraint

proc `=copy`(a: var Constraint, b: Constraint) {.error.}

proc `=destroy`(constr: var Constraint) =
  if constr.cp != nil:
    # Remove constraint from space and free it
    cpSpaceRemoveConstraint(constr.cp.space, constr.cp)
    proc cpConstraintFree(constr: ptr cpConstraint)
      {.importc, header: cpH.}
    cpConstraintFree(constr.cp)

proc initConstraint(cp: ptr cpConstraint): Constraint =
  Constraint(cp: cp)


# Shape wrapper

type
  Shape* = object
    cp: ptr cpShape

proc `=copy`(a: var Shape, b: Shape) {.error.}

proc `=destroy`(shape: var Shape) =
  if shape.cp != nil:
    # Remove shape from space and free it
    cpSpaceRemoveShape(shape.cp.space, shape.cp)
    proc cpShapeFree(shape: ptr cpShape)
      {.importc, header: cpH.}
    cpShapeFree(shape.cp)

proc initShape(cp: ptr cpShape): Shape =
  Shape(cp: cp)


# Constructors

proc wrap(phy: var Physics, cp: ptr cpBody): Body =
  proc cpSpaceAddBody(space: ptr cpSpace, body: ptr cpBody): ptr cpBody
    {.importc, header: cpH.}
  initBody(cpSpaceAddBody(phy.space, cp))

proc wrap(phy: var Physics, cp: ptr cpConstraint): Constraint =
  proc cpSpaceAddConstraint(
    space: ptr cpSpace, constr: ptr cpConstraint): ptr cpConstraint
    {.importc, header: cpH.}
  initConstraint(cpSpaceAddConstraint(phy.space, cp))

proc wrap(phy: var Physics, cp: ptr cpShape): Shape =
  proc cpSpaceAddShape(space: ptr cpSpace, shape: ptr cpShape): ptr cpShape
    {.importc, header: cpH.}
  initShape(cpSpaceAddShape(phy.space, cp))

proc createDynamic*(phy: var Physics, mass, moment: float): Body =
  proc cpBodyNew(mass, moment: float): ptr cpBody
    {.importc, header: cpH.}
  phy.wrap(cpBodyNew(mass, moment))

proc createStatic*(phy: var Physics): Body =
  proc cpBodyNewStatic(): ptr cpBody
    {.importc, header: cpH.}
  phy.wrap(cpBodyNewStatic())

proc createPivot*(
  phy: var Physics, a, b: Body,
  anchorA: Vec2 = (0.0, 0.0), anchorB: Vec2 = (0.0, 0.0),
): Constraint =
  proc cpPivotJointNew2(
    a, b: ptr cpBody, anchorA, anchorB: cpVect): ptr cpConstraint
    {.importc, header: cpH.}
  phy.wrap(cpPivotJointNew2(a.cp, b.cp, anchorA, anchorB))

proc createCircle*(
  phy: var Physics, body: Body,
  radius: float, offset: Vec2 = (0.0, 0.0)
): Shape =
  proc cpCircleShapeNew(
    body: ptr cpBody, radius: float, offset: cpVect): ptr cpShape
    {.importc, header: cpH.}
  phy.wrap(cpCircleShapeNew(body.cp, radius, offset))

proc createBox*(
  phy: var Physics, body: Body,
  w, h: float, radius: float = 0
): Shape =
  proc cpBoxShapeNew(
    body: ptr cpBody, w, h: float, radius: float): ptr cpShape
    {.importc, header: cpH.}
  phy.wrap(cpBoxShapeNew(body.cp, w, h, radius))

proc createPoly*(
  phy: var Physics, body: Body,
  verts: openArray[Vec2], radius: float = 0,
): Shape =
  var cpVerts = newSeqOfCap[cpVect](verts.len)
  for vert in verts:
    cpVerts.add(vert)
  type cpTransform {.importc: "cpTransform", header: cpH.} = tuple
    a, b, c, d, tx, ty: float
  proc cpPolyShapeNew(
    body: ptr cpBody,
    count: int, verts: ptr cpVect,
    transform: cpTransform, radius: float): ptr cpShape
    {.importc, header: cpH.}
  phy.wrap(cpPolyShapeNew(
    body.cp,
    cpVerts.len, cpVerts[0].addr,
    (1.0, 0.0, 0.0, 1.0, 0.0, 0.0),
    radius,
  ))


# Gravity

proc `gravity=`*(phy: var Physics, value: Vec2) =
  proc cpSpaceSetGravity(space: ptr cpSpace, gravity: cpVect)
    {.importc, header: cpH.}
  cpSpaceSetGravity(phy.space, value)


# Frame

proc frame*(phy: var Physics) =
  proc cpSpaceStep(space: ptr cpSpace, dt: float)
    {.importc, header: cpH.}
  cpSpaceStep(phy.space, tim.dt)


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
