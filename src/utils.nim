template destroyFields*[T: object | tuple](obj: var T) =
  ## Call `=destroy` on each field of an object or tuple. Useful when
  ## implementing `=destroy`, to automatically destroy all of the fields.
  for _, value in fieldPairs(obj):
    `=destroy`(value)
