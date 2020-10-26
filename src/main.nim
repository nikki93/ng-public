import times

proc fib(n: int): int =
  if n <= 1:
    1
  else:
    fib(n - 1) + fib(n - 2)

block:
  let before = getTime()
  let res = fib(42)
  let after = getTime()
  echo("nim-c: res: ", res, ", took: ", (after - before).inMilliseconds(), "ms")

block:
  proc cFib(n: cint): cint {.importc.}

  let before = getTime()
  let res = cFib(42)
  let after = getTime()
  echo("c: res: ", res, ", took: ", (after - before).inMilliseconds(), "ms")
