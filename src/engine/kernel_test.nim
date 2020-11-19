import times

import kernel

proc main() =
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

    ker.isort(Stuff, proc (a: auto, b: auto): auto = a.i < b.i)

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

main()
