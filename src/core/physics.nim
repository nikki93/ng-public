## Physics engine that uses Chipmunk Game Dynamics under the hood. Details
## on physics properties and behavior can be found in the Chipmunk manual
## (http://chipmunk-physics.net/release/ChipmunkLatest-Docs/ ). The
## documentation here just covers aspects specific to this module.
## 
## Types `Body`, `Constraint` and `Shape` which wrap Chipmunk objects
## automatically remove the objects and destroy them in their destructor. They
## can also store an association to an `Entity` for game logic purposes.

import timing, kernel, graphics, utils


const cpH = "\"precomp.h\""

type
  cpSpace {.importc: "cpSpace", header: cpH.} = object

  cpBody {.importc: "cpBody", header: cpH.} = object
    space: ptr cpSpace
    userData: uint32

  cpConstraint {.importc: "cpConstraint", header: cpH.} = object
    space: ptr cpSpace
    userData: uint32

  cpShapeType {.importc: "cpShapeType", header: cpH.} = enum
    CircleShape
    SegmentShape
    PolyShape

  cpShapeClass {.importc: "cpShapeClass", header: cpH.} = object
    `type`: cpShapeType

  cpShape {.importc: "cpShape", header: cpH.} = object
    klass: ptr cpShapeClass
    space: ptr cpSpace
    userData: uint32

  cpShapeFilter {.importc: "cpShapeFilter", header: cpH.} = object

  cpVect {.importc: "cpVect", header: cpH.} = object
    x, y: float


  Vec2* = tuple
    x, y: float

  BodyKind* {.importc: "cpBodyType", header: cpH.} = enum
    Dynamic
    Kinematic
    Static

  Body* = object
    cp: ptr cpBody

  Constraint* = object
    cp: ptr cpConstraint

  Shape* = object
    cp: ptr cpShape

  Physics = object
    space: ptr cpSpace
    background: Body

    stepAccum: float


# `cpVect` <-> `Vec2`

converter toVec2(value: cpVect): Vec2 {.inline.} =
  result.x = value.x
  result.y = value.y

converter toCpVect(value: Vec2): cpVect {.inline.} =
  result.x = value.x
  result.y = value.y


# Chipmunk object removal

proc remove(body: ptr cpBody) {.inline.} =
  proc cpSpaceRemoveBody(space: ptr cpSpace, body: ptr cpBody)
    {.importc, header: cpH.}
  if body.space != nil:
    cpSpaceRemoveBody(body.space, body)

proc remove(constr: ptr cpConstraint) {.inline.} =
  proc cpSpaceRemoveConstraint(space: ptr cpSpace, constr: ptr cpConstraint)
    {.importc, header: cpH.}
  if constr.space != nil:
    cpSpaceRemoveConstraint(constr.space, constr)

proc remove(shape: ptr cpShape) {.inline.} =
  proc cpSpaceRemoveShape(space: ptr cpSpace, shape: ptr cpShape)
    {.importc, header: cpH.}
  if shape.space != nil:
    cpSpaceRemoveShape(shape.space, shape)


# Body wrapper

proc cpBodyEachShape(
  body: ptr cpBody,
  fn: proc(body: ptr cpBody, shape: ptr cpShape, data: pointer)
    {.cdecl.},
  data: pointer)
  {.importc, header: cpH.}

proc cpBodyLocalToWorld(body: ptr cpBody, point: cpVect): cpVect
  {.importc, header: cpH.}

proc cpPolyShapeGetCount(shape: ptr cpShape): int
  {.importc, header: cpH.}

proc cpPolyShapeGetVert(shape: ptr cpShape, index: int): cpVect
  {.importc, header: cpH.}

proc `=copy`(a: var Body, b: Body) {.error.}

proc `=destroy`(body: var Body) {.inline.} =
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
      body.cp, proc(body, constr, data: auto) {.cdecl.} = remove(constr), nil)
    cpBodyEachShape(
      body.cp, proc(body, shape, data: auto) {.cdecl.} = remove(shape), nil)

    # Remove body from space and free it
    remove(body.cp)
    proc cpBodyFree(body: ptr cpBody)
      {.importc, header: cpH.}
    cpBodyFree(body.cp)

  destroyFields(body)

proc initBody(cp: ptr cpBody): Body =
  cp.userData = nullEntity.toIntegral
  Body(cp: cp)

proc entity*(body: Body): Entity {.inline.} =
  body.cp.userData.toEntity

proc `entity=`*(body: Body, ent: Entity) {.inline.} =
  body.cp.userData = ent.toIntegral

proc kind*(body: Body): BodyKind {.inline.} =
  proc cpBodyGetType(body: ptr cpBody): BodyKind
    {.importc, header: cpH.}
  cpBodyGetType(body.cp)

proc `kind=`*(body: Body, kind: BodyKind) {.inline.} =
  proc cpBodySetType(body: ptr cpBody, kind: BodyKind)
    {.importc, header: cpH.}
  cpBodySetType(body.cp, kind)

proc mass*(body: Body): float {.inline.} =
  proc cpBodyGetMass(body: ptr cpBody): float
    {.importc, header: cpH.}
  cpBodyGetMass(body.cp)

proc `mass=`*(body: Body, mass: float) {.inline.} =
  proc cpBodySetMass(body: ptr cpBody, mass: float)
    {.importc, header: cpH.}
  cpBodySetMass(body.cp, mass)

proc moment*(body: Body): float {.inline.} =
  proc cpBodyGetMoment(body: ptr cpBody): float
    {.importc, header: cpH.}
  cpBodyGetMoment(body.cp)

proc `moment=`*(body: Body, moment: float) {.inline.} =
  proc cpBodySetMoment(body: ptr cpBody, moment: float)
    {.importc, header: cpH.}
  cpBodySetMoment(body.cp, moment)

proc position*(body: Body): Vec2 {.inline.} =
  proc cpBodyGetPosition(body: ptr cpBody): cpVect
    {.importc, header: cpH.}
  cpBodyGetPosition(body.cp)

proc `position=`*(body: Body, value: Vec2) {.inline.} =
  proc cpBodySetPosition(body: ptr cpBody, value: cpVect)
    {.importc, header: cpH.}
  cpBodySetPosition(body.cp, value)

proc velocity*(body: Body): Vec2 {.inline.} =
  proc cpBodyGetVelocity(body: ptr cpBody): cpVect
    {.importc, header: cpH.}
  cpBodyGetVelocity(body.cp)

proc `velocity=`*(body: Body, value: Vec2) {.inline.} =
  proc cpBodySetVelocity(body: ptr cpBody, value: cpVect)
    {.importc, header: cpH.}
  cpBodySetVelocity(body.cp, value)

proc toWorld*(body: Body, point: Vec2): Vec2 {.inline.} =
  cpBodyLocalToWorld(body.cp, point)

proc toLocal*(body: Body, point: Vec2): Vec2 {.inline.} =
  proc cpBodyWorldToLocal(body: ptr cpBody, point: cpVect): cpVect
    {.importc, header: cpH.}
  cpBodyWorldToLocal(body.cp, point)

proc draw*(body: Body) =
  proc visit(body, shape, data: auto) {.cdecl.} =
    if shape.klass.`type` == PolyShape:
      let count = cpPolyShapeGetCount(shape)
      for i in 0..<count:
        let v1 = cpBodyLocalToWorld(body, cpPolyShapeGetvert(shape, i))
        let nextI = if i == count - 1: 0 else: i + 1
        let v2 = cpBodyLocalToWorld(body, cpPolyShapeGetVert(shape, nextI))
        gfx.drawLine(v1.x, v1.y, v2.x, v2.y)
  cpBodyEachShape(body.cp, visit, nil)


# Constraint wrapper

proc `=copy`(a: var Constraint, b: Constraint) {.error.}

proc `=destroy`(constr: var Constraint) {.inline.} =
  if constr.cp != nil:
    # Remove constraint from space and free it
    remove(constr.cp)
    proc cpConstraintFree(constr: ptr cpConstraint)
      {.importc, header: cpH.}
    cpConstraintFree(constr.cp)
  destroyFields(constr)

proc initConstraint(cp: ptr cpConstraint): Constraint =
  cp.userData = nullEntity.toIntegral
  Constraint(cp: cp)

proc entity*(constr: Constraint): Entity {.inline.} =
  constr.cp.userData.toEntity

proc `entity=`*(constr: Constraint, ent: Entity) {.inline.} =
  constr.cp.userData = ent.toIntegral

proc maxForce*(constr: Constraint): float {.inline.} =
  proc cpConstraintGetMaxForce(constr: ptr cpConstraint): float
    {.importc, header: cpH.}
  cpConstraintGetMaxForce(constr.cp)

proc `maxForce=`*(constr: Constraint, maxForce: float) {.inline.} =
  proc cpConstraintSetMaxForce(constr: ptr cpConstraint, maxForce: float)
    {.importc, header: cpH.}
  cpConstraintSetMaxForce(constr.cp, maxForce)

proc maxBias*(constr: Constraint): float {.inline.} =
  proc cpConstraintGetMaxBias(constr: ptr cpConstraint): float
    {.importc, header: cpH.}
  cpConstraintGetMaxBias(constr.cp)

proc `maxBias=`*(constr: Constraint, maxBias: float) {.inline.} =
  proc cpConstraintSetMaxBias(constr: ptr cpConstraint, maxBias: float)
    {.importc, header: cpH.}
  cpConstraintSetMaxBias(constr.cp, maxBias)


# Shape wrapper

proc `=copy`(a: var Shape, b: Shape) {.error.}

proc `=destroy`(shape: var Shape) {.inline.} =
  if shape.cp != nil:
    # Remove shape from space and free it
    remove(shape.cp)
    proc cpShapeFree(shape: ptr cpShape)
      {.importc, header: cpH.}
    cpShapeFree(shape.cp)
  destroyFields(shape)

proc initShape(cp: ptr cpShape): Shape =
  cp.userData = nullEntity.toIntegral
  Shape(cp: cp)

proc entity*(shape: Shape): Entity {.inline.} =
  shape.cp.userData.toEntity

proc `entity=`*(shape: Shape, ent: Entity) {.inline.} =
  shape.cp.userData = ent.toIntegral

proc radius*(shape: Shape): float {.inline.} =
  if shape.cp.klass.`type` == CircleShape:
    proc cpCircleShapeGetRadius(shape: ptr cpShape): float
      {.importc, header: cpH.}
    return cpCircleShapeGetRadius(shape.cp)
  if shape.cp.klass.`type` == SegmentShape:
    proc cpSegmentShapeGetRadius(shape: ptr cpShape): float
      {.importc, header: cpH.}
    return cpSegmentShapeGetRadius(shape.cp)
  if shape.cp.klass.`type` == PolyShape:
    proc cpPolyShapeGetRadius(shape: ptr cpShape): float
      {.importc, header: cpH.}
    return cpPolyShapeGetRadius(shape.cp)

proc `radius=`*(shape: Shape, radius: float) {.inline.} =
  if shape.cp.klass.`type` == CircleShape:
    proc cpCircleShapeSetRadius(shape: ptr cpShape, radius: float)
      {.importc, header: cpH.}
    cpCircleShapeSetRadius(shape.cp, radius)
  if shape.cp.klass.`type` == SegmentShape:
    proc cpSegmentShapeSetRadius(shape: ptr cpShape, radius: float)
      {.importc, header: cpH.}
    cpSegmentShapeSetRadius(shape.cp, radius)
  if shape.cp.klass.`type` == PolyShape:
    proc cpPolyShapeSetRadius(shape: ptr cpShape, radius: float)
      {.importc, header: cpH.}
    cpPolyShapeSetRadius(shape.cp, radius)

proc numVerts*(shape: Shape): int {.inline.} =
  cpPolyShapeGetCount(shape.cp)

proc vert*(shape: Shape, index: int): Vec2 {.inline.} =
  cpPolyShapeGetVert(shape.cp, index)


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
  type cpTransform {.importc: "cpTransform", header: cpH.} = object
    a, b, c, d, tx, ty: float
  let transform = cpTransform(
    a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
  proc cpPolyShapeNew(
    body: ptr cpBody,
    count: int, verts: ptr cpVect,
    transform: cpTransform, radius: float): ptr cpShape
    {.importc, header: cpH.}
  phy.wrap(cpPolyShapeNew(
    body.cp,
    cpVerts.len, cpVerts[0].addr,
    transform,
    radius,
  ))


# Queries

let cpShapeFilterAll
  {.importc: "CP_SHAPE_FILTER_ALL", nodecl.}: cpShapeFilter

type
  SegmentQueryResult* = object
    entity*: Entity
    point*, normal*: Vec2
    alpha*: float

proc segmentQuery*(
  phy: var Physics,
  start, finish: Vec2,
  radius: float = 0,
): seq[SegmentQueryResult] =
  proc cpSpaceSegmentQuery(
    space: ptr cpSpace,
    start, finish: cpVect, radius: float,
    filter: cpShapeFilter,
    handler: proc(
      shape: ptr cpShape,
      point, normal: cpVect, alpha: float,
      data: pointer) {.cdecl.},
    data: pointer)
    {.importc, header: cpH.}
  proc cHandler(
    shape: ptr cpShape,
    point, normal: cpVect, alpha: float,
    data: pointer) {.cdecl.} =
    var results = cast[ptr seq[SegmentQueryResult]](data)
    results[].add(SegmentQueryResult(
      entity: shape.userData.toEntity,
      point: point, normal: normal,
      alpha: alpha))
  cpSpaceSegmentQuery(
    phy.space, start, finish, radius,
    cpShapeFilterAll, cHandler, result.addr)


# Misc

proc background*(phy: var Physics): lent Body =
  phy.background

proc reindex*(phy: var Physics, body: Body) =
  proc cpSpaceReindexShapesForBody(space: ptr cpSpace, body: ptr cpBody)
    {.importc, header: cpH.}
  cpSpaceReindexShapesForBody(phy.space, body.cp)


# Frame

proc frame*(phy: var Physics, fixedTimeStep: bool = false) =
  ## Step the physics simulation. Reads the delta time from the timing module.
  ## A "fixed timestep" can optionally be enabled, which uses the method
  ## explained in
  ## https://gafferongames.com/post/fix_your_timestep/#free-the-physics .
  proc cpSpaceStep(space: ptr cpSpace, dt: float)
    {.importc, header: cpH.}
  if fixedTimeStep:
    phy.stepAccum += tim.dt
    const stepPeriod = 1 / 120.0
    while phy.stepAccum > stepPeriod:
      cpSpaceStep(phy.space, stepPeriod)
      phy.stepAccum -= stepPeriod
  else:
    cpSpaceStep(phy.space, tim.dt)


# Init / deinit

proc init*(phy: var Physics) =
  # Init Chipmunk space
  proc cpSpaceNew(): ptr cpSpace
    {.importc, header: cpH.}
  phy.space = cpSpaceNew()

  # Init background body
  phy.background = phy.createStatic()

  echo "initialized physics"

proc deinit*(phy: var Physics) =
  # Destroy background body
  `=destroy`(phy.background)
  wasMoved(phy.background)

  # Destroy Chipmunk space
  if phy.space != nil:
    proc cpSpaceFree(space: ptr cpSpace)
      {.importc, header: cpH.}
    cpSpaceFree(phy.space)

  echo "deinitialized physics"


# Singleton

proc `=copy`(a: var Physics, b: Physics) {.error.}

var phy*: Physics
