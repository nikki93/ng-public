## Loading and saving scenes, components and entities from / to JSON.

import std/[json, macros, hashes, sets]

import ng

import all


# Automatically-handled field types

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
      let valJson = node.getOrDefault(name)
      if valJson != nil:
        loadField(val, valJson)
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

  # Custom `load` hook
  when compiles(save(inst[], ent, node)):
    save(inst[], ent, node)


# Scenes

proc loadScene*(root: JsonNode) =
  ## Load a game scene into the kernel from a JSON node
  for entJson in root["entities"]: # Each entity
    let ent = ker.create()
    for typeJson in entJson["types"]: # Each type
      let typeName = typeJson["_type"].getStr()
      let typeNameHash = hash(typeName)
      forEachRegisteredTypeSkip(T, "nosave"): # Skip `{.nosave.}` types
        const TName = $T
        const TNameHash = hash($T) # Can hash `$T` at compile time
        if typeNameHash == TNameHash and typeName == TName:
          loadComponent(T, ent, typeJson)

proc loadScene*(path: string) =
  ## Load a game scene into the kernel from an asset path
  loadScene(parseJson(open(path).readAll()))

proc saveScene*(): JsonNode =
  ## Save the current scene from the kernel as a JSON node
  %{
    "entities": block:
      let entities = newJArray()
      for ent in ker.each():
        entities.add(%{
          "types": block:
            let types = newJArray()
            forEachRegisteredTypeSkip(T, "nosave"): # Skip `{.nosave.}` types
              let inst = ker.get(T, ent)
              if inst != nil:
                types.add:
                  let typeJson = newJObject() # Node for this type
                  typeJson["_type"] = %($T) # Save type name
                  saveComponent(inst, ent, typeJson)
                  typeJson
            types
        })
      entities
  }


# Warn about fields we skipped automatic save / load for
when not defined(nimsuggest):
  import std/[strutils, sequtils]
  {.hint: "automatic save / load skipped for: " & autoSkipped.toSeq.join(", ").}
