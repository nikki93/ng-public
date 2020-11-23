## Implementation for 'saveload'. This is in a separate module so that it can
## use system hooks, while still allowing 'saveload' to be imported from
## systems.

{.used.}

import std/[json, macros, hashes, sets]

import core

import saveload

import systems/all


# Components

var autoSkipped {.compileTime.}: OrderedSet[string]

proc loadComponent(T: typedesc, ent: Entity, node: JsonNode) =
  ## Load a component into an entity, adding it if needed

  # Get or add instance
  var inst = ker.get(T, ent)
  if inst == nil:
    inst = ker.add(T, ent)

  # Fields
  for name, val in fieldPairs(inst[]):
    when compiles(JsonNode().to(typeof(val))):
      # Auto-saveable field
      let valNode = node.getOrDefault(name)
      if valNode != nil:
        val = valNode.to(typeof(val))
    else:
      # Not auto-saveable, track and hint
      static:
        autoSkipped.incl($T & "." & name & ": " & $typeof(val))

  # Custom `load` hook
  when compiles(load(inst[], ent, node)):
    load(inst[], ent, node)

proc saveComponent[T](inst: ptr T, ent: Entity, node: JsonNode) =
  ## Save a component

  # Fields
  for name, val in fieldPairs(inst[]):
    when compiles(%val):
      # Auto-loadable field
      node[name] = %val
    else:
      # Not auto-loadable, track and hint
      static:
        autoSkipped.incl($T & "." & name & ": " & $typeof(val))

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
  {.hint: "automatic save / load skipped for:\n    " &
    autoSkipped.toSeq.join("\n    ").}
