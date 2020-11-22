## Loading and saving scenes. Implementation of this is mostly in
## 'saveload_impl' so that that file can use system hooks.

import std/json

import ng


# Implementations to be filled-in by 'saveload_impl'

var loadSceneImpl*: proc(
  root: JsonNode,
  extra: proc(ent: Entity, node: JsonNode),
)
  ## Implemented in 'saveload_impl'

var saveSceneImpl*: proc(
  filter: proc(ent: Entity): bool,
  extra: proc(ent: Entity, node: JsonNode),
): JsonNode
  ## Implemented in 'saveload_impl'


# Public API

proc loadScene*(
  root: JsonNode,
  extra: proc(ent: Entity, node: JsonNode) = nil,
) =
  ## Load a game scene into the kernel from a JSON node
  loadSceneImpl(root, extra)

proc loadScene*(
  path: string,
  extra: proc(ent: Entity, node: JsonNode) = nil,
) =
  ## Load a game scene into the kernel from an asset path
  loadScene(parseJson(open(path).readAll()), extra)

proc saveScene*(
  filter: proc(ent: Entity): bool = nil,
  extra: proc(ent: Entity, node: JsonNode) = nil,
): JsonNode =
  ## Save the current scene from the kernel as a JSON node
  saveSceneImpl(filter, extra)
