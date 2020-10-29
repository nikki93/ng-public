echo "hello from nim->c++"

import times

import kernel


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

  echo "all tests passed!"



proc bench() =
  const N = 100000000

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

  var nAll = 0

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
        inc nAll
    let after = getTime()
    echo("creation took ", (after - before).inMilliseconds, "ms")

  block:
    let before = getTime()
    var found = 0
    for _, c1, c2, c3 in ker.each(C1, C2, C3):
      inc found
    let after = getTime()
    echo("iteration took ", (after - before).inMilliseconds, "ms")
    doAssert found == nAll

basicTest()
#bench()
