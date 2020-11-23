## Implementation for 'saveload'. This is in a separate module so that it can
## use system hooks, while still allowing 'saveload' to be imported from
## systems.

{.used.}

import std/[json, macros, hashes, sets]

import ng

import saveload

import systems/all


# Automatically-handled field types

proc loadField(val: var bool, node: JsonNode) {.used.} =
  val = node.getBool()

proc saveField(val: bool): JsonNode {.used.} =
  %val

proc loadField(val: var int, node: JsonNode) {.used.} =
  val = node.getInt()

proc saveField(val: int): JsonNode {.used.} =
  %val

proc loadField(val: var float, node: JsonNode) {.used.} =
  val = node.getFloat()

proc saveField(val: float): JsonNode {.used.} =
  %val

proc loadField(val: var string, node: JsonNode) {.used.} =
  val = node.getStr()

proc saveField(val: string): JsonNode {.used.} =
  %val


# Components

var autoSkipped {.compileTime.}: HashSet[string]

proc loadComponent(T: typedesc, ent: Entity, node: JsonNode) =
  ## Load a component into an entity, adding it if needed

  # Get or add instance
  var inst = ker.get(T, ent)
  if inst == nil:
    inst = ker.add(T, ent)

  # Fields
  for name, val in fieldPairs(inst[]):
    when compiles(loadField(val, JsonNode())):
      # Simple field
      let valNode = node.getOrDefault(name)
      if valNode != nil:
        loadField(val, valNode)
    else:
      # Not a simple field, keep track and hint
      static:
        autoSkipped.incl($T & "." & name)

  # Custom `load` hook
  when compiles(load(inst[], ent, node)):
    load(inst[], ent, node)

proc saveComponent[T](inst: ptr T, ent: Entity, node: JsonNode) =
  ## Save a component

  # Fields
  for name, val in fieldPairs(inst[]):
    when compiles(saveField(val)):
      # Simple field
      node[name] = saveField(val)
    else:
      # Not a simple field, track and hint
      static:
        autoSkipped.incl($T & "." & name)

  # Custom `save` hook
  when compiles(save(inst[], ent, node)):
    save(inst[], ent, node)


# Scenes

loadSceneImpl = proc(
  root: JsonNode,
  extra: proc(ent: Entity, node: JsonNode),
) =
  for entNode in root["entities"]: # Each entity
    let ent = ker.create()
    for typeNode in entNode["types"]: # Each type
      let typeName = typeNode["_type"].getStr()
      let typeNameHash = hash(typeName)
      forEachRegisteredTypeSkip(T, "nosave"): # Skip `{.nosave.}` types
        const TName = $T
        const TNameHash = hash($T) # Can hash `$T` at compile time
        if typeNameHash == TNameHash and typeName == TName:
          loadComponent(T, ent, typeNode)
    if extra != nil:
      extra(ent, entNode)

saveSceneImpl = proc(
  filter: proc(ent: Entity): bool,
  extra: proc(ent: Entity, node: JsonNode),
): JsonNode =
  %{
    "entities": block:
      let entities = newJArray()
      for ent in ker.each():
        if filter != nil and not filter(ent):
          continue # Skip if filtered-out
        var entNode = %{
          "types": block:
            let types = newJArray()
            forEachRegisteredTypeSkip(T, "nosave"): # Skip `{.nosave.}` types
              let inst = ker.get(T, ent)
              if inst != nil:
                types.add:
                  let typeNode = newJObject() # Node for this type
                  typeNode["_type"] = %($T) # Save type name
                  saveComponent(inst, ent, typeNode)
                  typeNode
            types
        }
        if extra != nil:
          extra(ent, entNode)
        entities.add(entNode)
      entities
  }


# Warn about fields we skipped automatic save / load for
when not defined(nimsuggest):
  import std/[strutils, sequtils]
  {.hint: "automatic save / load skipped for: " & autoSkipped.toSeq.join(", ").}
