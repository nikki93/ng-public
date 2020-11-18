import std/[json, strutils]

import ng

import all


# Loading

var loadSkipped {.compileTime.}: seq[string]


proc load(T: typedesc, ent: Entity, node: JsonNode) =
  ## Load a type into an entity, adding it if needed

  # Simple field loaders
  proc loadField(val: var int, node: JsonNode) {.used.} =
    val = node.getInt()
  proc loadField(val: var float, node: JsonNode) {.used.} =
    val = node.getFloat()
  proc loadField(val: var string, node: JsonNode) {.used.} =
    val = node.getStr()

  # Read into type from JSON
  var inst = ker.get(T, ent)
  if inst == nil:
    inst = ker.add(T, ent)
  for name, val in fieldPairs(inst[]):
    when compiles(loadField(val, JsonNode())):
      # Simple field
      let valJson = node.getOrDefault(name)
      if valJson != nil:
        loadField(val, valJson)
    else:
      # Not a simple field, keep track and hint
      static:
        loadSkipped.add($T & "." & name)

  # Call `load` hook if type has one
  when compiles(load(inst[], ent, node)):
    load(inst[], ent, node)


proc loadScene*(path: string) =
  ## Load a game scene into the kernel

  let root = parseJson(open(path).readAll())
  for entJson in root["entities"]: # Each entity
    let ent = ker.create()
    for typeJson in entJson["types"]: # Each type
      let typeName = typeJson["_type"].getStr()
      forEachRegisteredType(T): # Check which registered type this is
        if typeName == $T:
          load(T, ent, typeJson)


when not defined(nimsuggest):
  {.hint: "automatic loading skipped for: " & loadSkipped.join(", ").}