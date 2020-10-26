import times

proc fib(n: int): int =
  if n <= 1:
    1
  else:
    fib(n - 1) + fib(n - 2)

let before = getTime()
let res = fib(42)
let after = getTime()
echo("nim-js: res: ", res, ", took: ", (after - before).inMilliseconds(), "ms")
