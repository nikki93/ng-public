## Imports and re-exports all system modules

import std/[os, macros]

import types
export types

macro generateImportsAndExports() =
  result = newStmtList()
  for kind, path in walkDir("./src/systems"):
    if kind == pcFile:
      if (let name = path.splitFile.name; name != "all"):
        let ident = newIdentNode(name)
        result.add quote do:
          import `ident`
          export `ident`

generateImportsAndExports()
