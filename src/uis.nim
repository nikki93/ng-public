## Interface to DOM-based user interface in the browser

import std/macros

import utils

when defined(emscripten):
  {.emit: "#include <emscripten.h>".}

type
  UI = object


# Elem

when defined(emscripten):
  proc JS_uiElemOpenStart(tag: cstring) {.importc.}
  proc JS_uiElemOpenStartKeyInt(tag: cstring, key: int) {.importc.}
  proc JS_uiElemOpenStartKeyStr(tag: cstring, key: cstring) {.importc.}

  proc JS_uiElemOpenEnd() {.importc.}

  proc JS_uiElemClose(tag: cstring) {.importc.}

  proc JS_uiAttrInt(name: cstring, value: int) {.importc.}
  proc JS_uiAttrFloat(name: cstring, value: float) {.importc.}
  proc JS_uiAttrBool(name: cstring, value: bool) {.importc.}
  proc JS_uiAttrStr(name: cstring, value: cstring) {.importc.}
  proc JS_uiAttrClass(value: cstring) {.importc.}
else:
  proc JS_uiElemOpenStart(tag: cstring) = discard
  proc JS_uiElemOpenStartKeyInt(tag: cstring, key: int) = discard
  proc JS_uiElemOpenStartKeyStr(tag: cstring, key: cstring) = discard

  proc JS_uiElemOpenEnd() = discard

  proc JS_uiElemClose(tag: cstring) = discard

  proc JS_uiAttrInt(name: cstring, value: int) = discard
  proc JS_uiAttrFloat(name: cstring, value: float) = discard
  proc JS_uiAttrBool(name: cstring, value: bool) = discard
  proc JS_uiAttrStr(name: cstring, value: cstring) = discard
  proc JS_uiAttrClass(value: cstring) = discard


proc elemOpenStart(ui: var UI, tag: string) =
  JS_uiElemOpenStart(tag)

proc elemOpenEnd(ui: var UI) =
  JS_uiElemOpenEnd()

proc elemClose(ui: var UI, tag: string) =
  JS_uiElemClose(tag)

proc attr(ui: var UI, name: string, value: int) =
  JS_uiAttrInt(name, value)

proc attr(ui: var UI, name: string, value: float) =
  JS_uiAttrFloat(name, value)

proc attr(ui: var UI, name: string, value: bool) =
  JS_uiAttrBool(name, value)

proc attr(ui: var UI, name: string, value: string) =
  JS_uiAttrStr(name, value)

proc class(ui: var UI, value: string) =
  JS_uiAttrClass(value)


macro elem*(ui: var UI, tag: string, args: varargs[untyped]) =
  const debug = false

  when debug:
    for i, arg in args:
      echo "arg[", i, "]:\n", arg.treeRepr, "\n"

  result = newStmtList()

  result.add quote do:
    elemOpenStart(`ui`, `tag`)

  for node in args:
    case node.kind:
    of nnkStrLit:
      result.add quote do:
        class(`ui`, `node`)
    of nnkExprColonExpr, nnkExprEqExpr:
      let name = newLit($node[0])
      let value = node[1]
      result.add quote do:
        attr(`ui`, `name`, `value`)
      discard
    of nnkStmtList:
      discard
    else:
      error("`ui.elem` parameters must be attributes or a body", node)

  result.add quote do:
    elemOpenEnd(`ui`)

  if args.len > 0 and args.last.kind == nnkStmtList:
    result.add(args.last)

  result.add quote do:
    elemClose(`ui`, `tag`)

  when debug:
    echo "tree: ", result.treeRepr, "\n"
    echo "code: ", result.repr, "\n"


# Common elements

template box*(ui: var UI, args: varargs[untyped]) =
  elem(ui, "div", args)

template button*(ui: var UI, args: varargs[untyped]) =
  elem(ui, "button", args)


# Text

when defined(emscripten):
  proc JS_uiText(value: cstring) {.importc.}
else:
  proc JS_uiText(value: cstring) = discard

proc text*(ui: var UI, value: string) {.inline.} =
  JS_uiText(value)


# Events

when defined(emscripten):
  proc JS_uiEventCount(typ: cstring): int {.importc.}
else:
  proc JS_uiEventCount(typ: cstring): int = discard

template event*(ui: var UI, eventType: string, body: typed) =
  block:
    let count = JS_uiEventCount(eventType)
    for i in 1..count:
      body


# Patch

var thePatchProc: proc()

when defined(emscripten):
  proc JS_uiPatch(id: cstring) {.importc.}
else:
  proc JS_uiPatch(id: cstring) = discard

template patch*(ui: var UI, id: cstring, body: typed) =
  block:
    proc patchProc() =
      body
    thePatchProc = patchProc
    JS_uiPatch(id)
    thePatchProc = nil

when defined(emscripten):
  proc JS_uiCallPatchProc()
    {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
    if thePatchProc != nil:
      thePatchProc()


# Frame

when defined(emscripten):
  proc JS_uiClearEventCounts() {.importc.}
else:
  proc JS_uiClearEventCounts() = discard

template frame*(ui: var UI, body: typed) =
  body
  JS_uiClearEventCounts()


# Init / deinit

proc init(ui: var UI) =
  echo "initialzied ui"

proc `=destroy`(ui: var UI) =
  destroyFields(ui)
  echo "deinitialized ui"


# Singleton

proc `=copy`(a: var UI, b: UI) {.error.}

var ui*: UI ## The global instance for this module, on which to call
            ## the UI procedures
ui.init()
