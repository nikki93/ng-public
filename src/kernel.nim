# entt

const enttH = "<entt/entt.hpp>"


type
  Entity* {.importcpp: "entt::entity", header: enttH.} = object

  Registry {.importcpp: "entt::registry", header: enttH.} = object

  Kernel = object
    reg: Registry


var ker*: Kernel


let null* {.importcpp: "kernel_null".}: Entity
{.emit: "entt::entity kernel_null = entt::null;".}

proc `==`*(a: Entity, b: Entity): bool {.importcpp: "# == #".}


proc create*(ker: var Kernel): Entity {.inline.} =
  proc create(reg: var Registry): Entity
    {.importcpp.}
  ker.reg.create()

proc destroy*(ker: var Kernel, ent: Entity) {.inline.} =
  proc destroy(reg: var Registry, ent: Entity)
    {.importcpp.}
  ker.reg.destroy(ent)


proc add*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
  proc emplace[T](reg: var Registry, ent: Entity): ptr T
    {.importcpp: "&#.emplace<'*0>(#)".}
  result = ker.reg.emplace[:T](ent)
  zeroMem(result, sizeof(T))

proc remove*(ker: var Kernel, T: typedesc, ent: Entity) {.inline.} =
  proc remove[T](reg: var Registry, ent: Entity, _: ptr T)
    {.importcpp: "#.remove<'*3>(#)".}
  ker.reg.remove[:T](ent, nil)


proc has*(ker: var Kernel, T: typedesc, ent: Entity): bool {.inline.} =
  proc has[T](reg: var Registry, ent: Entity, _: ptr T): bool
    {.importcpp: "#.has<'*3>(#)".}
  ker.reg.has[:T](ent, nil)

proc get*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
  proc get[T](reg: var Registry, ent: Entity): ptr T
    {.importcpp: "&#.get<'*0>(#)".}
  ker.reg.get[:T](ent)


const useLambdaEach = true

iterator each*(ker: var Kernel, T1: typedesc): (Entity, ptr T1) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ">().each([&](auto pe_, auto &pc1_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_] : ", ker.reg, ".view<", T1, ">().proxy()) {"].}
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
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ">().each([&](auto pe_, auto &pc1_, auto &pc2_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_] : ", ker.reg, ".view<", T1, ", ", T2, ">().proxy()) {"].}
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

iterator each*(ker: var Kernel, T1, T2, T3: typedesc): (Entity, ptr T1, ptr T2, ptr T3) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ", ", T3, ">().each([&](auto pe_, auto &pc1_, auto &pc2_, auto &pc3_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_, pc3_] : ", ker.reg, ".view<", T1, ", ", T2, ", ", T3, ">().proxy()) {"].}
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

iterator each*(ker: var Kernel, T1, T2, T3, T4: typedesc): (Entity, ptr T1, ptr T2, ptr T3, ptr T4) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ", ", T3, ", ", T4, ">().each([&](auto pe_, auto &pc1_, auto &pc2_, auto &pc3_, auto &pc4_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_, pc3_, pc4_] : ", ker.reg, ".view<", T1, ", ", T2, ", ", T3, ", ", T4, ">().proxy()) {"].}
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


when defined(runTests):
  import times

  proc basicTest() =
    type Position = object
      x: float
      y: float

    type Sprite = object
      img: string

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
          if not ker.has(Sprite, e):
            sumX += pos.x
            sumY += pos.y
        doAssert sumX == mustSumX and sumY == mustSumY
      check(55, 110)
      for e in es:
        ker.destroy(e)
      check(0, 0)

    block: # has, remove
      doAssert ker.has(Sprite, ent)
      `=destroy`(ker.get(Sprite, ent)[]) # TODO(nikki): Make this automatic...
      ker.remove(Sprite, ent)
      doAssert not ker.has(Sprite, ent)
      var found = 0
      for _, pos, spr in ker.each(Position, Sprite):
        inc found
      doAssert found == 0

    block: # Destroy
      ker.destroy(ent)

    echo "basic tests passed!"


  proc bench() =
    echo "benchmarking..."

    const N = 0xfffff - 20 # Close to maximum

    type
      C1 = object
        x: float
      C2 = object
        x: float
        y: float
      C3 = object
        x: float
        y: float
        z: float

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


  basicTest()
  bench()
