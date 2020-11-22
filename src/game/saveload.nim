## Loading and saving scenes. Implementation of this is mostly in
## 'saveload_impl' so that that file can use system hooks.

import std/json


var loadSceneImpl*: proc(root: JsonNode)
  ## Implemented in 'saveload_impl'

var saveSceneImpl*: proc(): JsonNode
  ## Implemented in 'saveload_impl'


proc loadScene*(root: JsonNode) =
  ## Load a game scene into the kernel from a JSON node
  loadSceneImpl(root)

proc saveScene*(): JsonNode =
  ## Save the current scene from the kernel as a JSON node
  saveSceneImpl()

proc loadScene*(path: string) =
  ## Load a game scene into the kernel from an asset path
  loadScene(parseJson(open(path).readAll()))
