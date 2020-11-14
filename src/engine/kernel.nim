import macros, tables, sets


const enttH = "\"precomp.h\""

type
  Entity* {.importcpp: "entt::entity", header: enttH.} = object

  Registry {.importcpp: "entt::registry", header: enttH.} = object

  Kernel = object
    reg: Registry

    typeMetas: Table[string, TypeMeta]

  TypeMeta* = object
    add*: proc(ent: Entity): pointer
    remove*: proc(ent: Entity)
    get*: proc(ent: Entity): pointer


# Meta compile-time vars

var typeIdents {.compileTime.}: seq[NimNode]

var typeNames {.compileTime.}: HashSet[string]


# Ids

let null* {.importcpp: "kernel_null".}: Entity
{.emit: "entt::entity kernel_null = entt::null;".}

proc `==`*(a: Entity, b: Entity): bool {.importcpp: "# == #".}

proc toIntegral*(ent: Entity): uint32
  {.importcpp: "entt::to_integral(#)".}

proc toEntity*(value: uint32): Entity
  {.importcpp: "entt::entity(#)".}

proc `$`*(ent: Entity): string {.inline.} =
  "Entity(" & $ent.toIntegral & ")"


# Create / destroy

proc create*(ker: var Kernel): Entity {.inline.} =
  proc create(reg: var Registry): Entity
    {.importcpp.}
  ker.reg.create()

proc destroy*(ker: var Kernel, ent: Entity) {.inline.} =
  proc destroy(reg: var Registry, ent: Entity)
    {.importcpp.}
  for typeMeta in ker.typeMetas.mvalues: # `mvalues` to prevent copy
    typeMeta.remove(ent)
  ker.reg.destroy(ent)


# Get

proc get*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
  proc tryGet[T](reg: var Registry, ent: Entity): ptr T
    {.importcpp: "#.try_get<'*0>(#)".}
  ker.reg.tryGet[:T](ent)


# Add / remove

proc add*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
  static:
    if not typeNames.contains($T):
      error("type '" & $T & "' must be registered with ng.")
  proc emplace[T](reg: var Registry, ent: Entity): ptr T
    {.importcpp: "&#.emplace<'*0>(#)".}
  result = ker.reg.emplace[:T](ent)
  zeroMem(result, sizeof(T))

proc remove*(ker: var Kernel, T: typedesc, ent: Entity) {.inline.} =
  proc remove[T](reg: var Registry, ent: Entity, _: ptr T)
    {.importcpp: "#.remove<'*3>(#)".}
  var got = ker.get(T, ent)
  if got != nil:
    `=destroy`(got[])
    ker.reg.remove[:T](ent, nil)


# Queries

const useLambdaEach = false

iterator each*(ker: var Kernel): Entity =
  proc data(reg: var Registry): ptr Entity
    {.importcpp: "(entt::entity *) #.data()".}
  proc size(reg: var Registry): int
    {.importcpp: "size".}
  proc valid(reg: var Registry, ent: Entity): bool
    {.importcpp: "valid".}
  let dat = ker.reg.data()
  let sz = ker.reg.size()
  for i in 0..<sz:
    var ent: Entity
    {.emit: [ent, " = ", dat, "[", i, "];"].}
    if ker.reg.valid(ent):
      yield ent

iterator each*(ker: var Kernel, T1: typedesc): (Entity, ptr T1) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ">()",
      ".each([&](auto pe_, auto &pc1_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_] : ",
      ker.reg, ".view<", T1, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  yield(e, c1)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}

iterator each*(ker: var Kernel, T1, T2: typedesc): (Entity, ptr T1, ptr T2) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ">()",
      ".each([&](auto pe_, auto &pc1_, auto &pc2_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_] : ",
      ker.reg, ".view<", T1, ", ", T2, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  var c2: ptr T2
  {.emit: [c2, " = &pc2_;"].}
  yield(e, c1, c2)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}

iterator each*(ker: var Kernel, T1, T2, T3: typedesc):
    (Entity, ptr T1, ptr T2, ptr T3) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ", ", T3, ">()",
      ".each([&](auto pe_, auto &pc1_, auto &pc2_, auto &pc3_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_, pc3_] : ",
      ker.reg, ".view<", T1, ", ", T2, ", ", T3, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  var c2: ptr T2
  {.emit: [c2, " = &pc2_;"].}
  var c3: ptr T3
  {.emit: [c3, " = &pc3_;"].}
  yield(e, c1, c2, c3)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}

iterator each*(ker: var Kernel, T1, T2, T3, T4: typedesc):
    (Entity, ptr T1, ptr T2, ptr T3, ptr T4) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ", ", T3, ", ", T4, ">()",
      ".each([&](auto pe_, auto &pc1_, auto &pc2_, auto &pc3_, auto &pc4_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_, pc3_, pc4_] : ",
      ker.reg, ".view<", T1, ", ", T2, ", ", T3, ", ", T4, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  var c2: ptr T2
  {.emit: [c2, " = &pc2_;"].}
  var c3: ptr T3
  {.emit: [c3, " = &pc3_;"].}
  var c4: ptr T4
  {.emit: [c4, " = &pc4_;"].}
  yield(e, c1, c2, c3, c4)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}


# Clear

proc clear*(ker: var Kernel) {.inline.} =
  for ent in ker.each():
    ker.destroy(ent)

proc clear*[T](ker: var Kernel, _: typedesc[T]) {.inline.} =
  for ent, _ in ker.each(T):
    ker.remove(T, ent)


# Sort

proc isort*[T](
  ker: var Kernel,
  _: typedesc[T],
  compare: proc (a: ptr T, b: ptr T): bool {.cdecl.},
) {.inline.} =
  {.emit: [ker.reg, ".sort<", T, ">([&](const auto &a, const auto &b) {",
    "return ", compare, "(const_cast<", T, "*>(&a), const_cast<", T, "*>(&b));",
  "}, entt::insertion_sort{});"].}


# Init / deinit

proc init*(ker: var Kernel) =
  echo "initialized kernel"

proc deinit*(ker: var Kernel) =
  ker.clear()
  echo "deinitialized kernel"


# Singleton

proc `=copy`(a: var Kernel, b: Kernel) {.error.}

var ker*: Kernel


# Meta

macro ng*(body: untyped) =
  let ident = body[0][0]
  ident.expectKind nnkIdent
  typeIdents.add(ident)
  typeNames.incl($ident)
  body

proc registerTypeMeta[T](name: string) =
  ker.typeMetas[name] = TypeMeta(
    add: proc(ent: Entity): pointer =
      ker.add(T, ent),
    remove: proc(ent: Entity) =
      ker.remove(T, ent),
    get: proc(ent: Entity): pointer =
      ker.get(T, ent),
  )

macro initMeta*() =
  ## Initializes the ng meta system. This macro must be invoked after all
  ## registered types and their hooks have been defined, and before meta
  ## information is read.
  result = newStmtList()
  for typeIdent in typeIdents:
    let name = $typeIdent
    result.add quote do:
      registerTypeMeta[`typeIdent`](`name`)
  result = newBlockStmt(result)


# Tests

when isMainModule:
  import times

  type
    Position {.ng.} = object
      x: float
      y: float

    Sprite {.ng.} = object
      img: string

    C1 {.ng.} = object
      x: float
    C2 {.ng.} = object
      x: float
      y: float
    C3 {.ng.} = object
      x: float
      y: float
      z: float

    ResourceObj = object
      name: string
    Resource = ref ResourceObj

    Stuff1 {.ng.} = object
      name: string
      nums: seq[int]
      ress: seq[Resource]

    Stuff2 {.ng.} = object
      name: string
      nums: seq[int]
      ress: seq[Resource]

    Stuff {.ng.} = object
      i: int

  proc basic() =
    # create
    let ent = ker.create()
    doAssert ent != null

    block: # add
      var pos = ker.add(Position, ent)
      pos.x = 3
      pos.y = 4

      var spr = ker.add(Sprite, ent)
      spr.img.add("foo.png") # `.add` forces heap memory

    block: # get
      var pos = ker.get(Position, ent)
      doAssert pos.x == 3 and pos.y == 4

      var spr = ker.get(Sprite, ent)
      doAssert spr.img == "foo.png"

    block: # each
      var found = 0
      for _, pos, spr in ker.each(Position, Sprite):
        doAssert pos.x == 3 and pos.y == 4
        inc found
      doAssert found == 1

      var es: seq[Entity]
      for i in 1..10:
        let e = ker.create()
        es.add(e)
        let p = ker.add(Position, e)
        p.x = i.toFloat
        p.y = 2 * i.toFloat
      proc check(mustSumX, mustSumY: float) =
        var sumX, sumY: float
        for e, pos in ker.each(Position):
          if ker.get(Sprite, e) == nil:
            sumX += pos.x
            sumY += pos.y
        doAssert sumX == mustSumX and sumY == mustSumY
      check(55, 110)
      for e in es:
        ker.destroy(e)
      check(0, 0)

    block: # get, remove
      doAssert ker.get(Sprite, ent) != nil
      ker.remove(Sprite, ent)
      doAssert ker.get(Sprite, ent) == nil
      var found = 0
      for _, pos, spr in ker.each(Position, Sprite):
        inc found
      doAssert found == 0

    block: # destroy
      ker.destroy(ent)

    echo "basic tests passed!"


  proc bench() =
    echo "benchmarking..."

    const N = 0xfffff - 20 # Close to maximum

    var expected = 0

    block:
      let before = getTime()
      for i in 0..<N:
        let e = ker.create()
        discard ker.add(C1, e)
        if i mod 2 == 0:
          discard ker.add(C2, e)
        if i mod 3 == 0:
          discard ker.add(C3, e)
        if i mod 2 == 0 and i mod 3 == 0:
          inc expected
      let after = getTime()
      echo("creation took ", (after - before).inMilliseconds, "ms")

    block:
      let before = getTime()
      var found = 0
      for _, c1, c2, c3 in ker.each(C1, C2, C3):
        inc found
      let after = getTime()
      echo("iteration took ", (after - before).inMilliseconds, "ms")
      doAssert found == expected

    echo "benchmark passed!"


  proc leaks() =
    var es: seq[Entity]

    block:
      var ress: seq[Resource]
      for i in 0..<20:
        let res = Resource()
        res.name.add("res" & $i)
        ress.add(res)

      for i in 0..<400:
        let e = ker.create()
        es.add(e)
        let s1 = ker.add(Stuff1, e)
        s1.name.add("stuff1" & $i)
        for j in 0..<(i mod 10):
          s1.nums.add(j)
        for j in 0..<(i mod 5):
          s1.ress.add(ress[(i + j * i) mod ress.len])
        if i mod 2 == 0:
          let s2 = ker.add(Stuff2, e)
          s2.name.add("stuff2" & $i)
          for j in 0..<(i mod 20):
            s2.nums.add(j)
          for j in 0..<(i mod 10):
            s2.ress.add(ress[(2 * i + 3 * j * i) mod ress.len])

    const fullTest = true
    if fullTest: # Tests destroy, remove, clear, shutdown
      for i in 0..<(es.len div 2):
        ker.destroy(es[i])
      var i = 0
      for e, _ in ker.each(Stuff1):
        inc i
        if i mod 2 == 0: # Leave some unremoved to test shutdown
          ker.remove(Stuff1, e)
      ker.clear(Stuff2)
      # Don't explicitly clear `Stuff1`, to test shutdown
    else: # Only tests clear
      ker.clear(Stuff1)
      ker.clear(Stuff2)

    echo "leak check passed!"


  proc sort() =
    for i in 0..<10:
      let e = ker.create();
      let s = ker.add(Stuff, e)
      s.i = 10 - i

    ker.isort(Stuff, proc (a: auto, b: auto): auto {.cdecl.} = a.i < b.i)

    var order: seq[int]
    for _, s in ker.each(Stuff):
      order.add(s.i)
    for i in 0..<(order.len - 1):
      doAssert order[i] < order[i + 1]

    echo "sort test passed!"


  ker.init()
  initMeta()

  basic()
  bench()
  leaks()
  sort()

  ker.deinit()
