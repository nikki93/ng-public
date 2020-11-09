## Interface to DOM-based user interface in the browser. All operations
## no-op cleanly on non-browser platforms.

import std/macros
when defined(emscripten):
  import std/strutils

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

  proc elemOpenStart(ui: var UI, tag: string) =
    JS_uiElemOpenStart(tag)
  proc elemOpenStart(ui: var UI, tag: string, key: int) =
    JS_uiElemOpenStartKeyInt(tag, key)
  proc elemOpenStart(ui: var UI, tag: string, key: string) =
    JS_uiElemOpenStartKeyStr(tag, key)

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
  ## Display a DOM-based UI element. A `tag` is always required and is the
  ## tag name to pass to the DOM. `args` can include:
  ##  - Named attributes with `attr: val` or `attr = val` syntax. The
  ##    attributes are passed through to the DOM. The special attribute
  ##    named `key` can be used to distinguish elements for performance
  ##    and is not sent to the DOM.
  ##  - A string literal by itself, which is passed as the `class`
  ##    attribute.
  ##  - A statement list, which is run "inside" the element. Elements
  ##    displayed inside become children of the outer element. `ui.event` and
  ##    `ui.valueStr` (and the other value procs) need to run inside an
  ##    element too, and apply to the enclosing element.

  when not defined(emscripten):
    result = newStmtList()
  else:
    const debug = false

    when debug:
      for i, arg in args:
        echo "arg[", i, "]:\n", arg.treeRepr, "\n"

    result = newStmtList()

    # Check for key
    var key: NimNode
    for node in args:
      if node.kind in {nnkExprColonExpr, nnkExprEqExpr} and $node[0] == "key":
        key = node[1]

    # Start open
    if key != nil:
      result.add quote do:
        elemOpenStart(`ui`, `tag`, `key`)
    else:
      result.add quote do:
        elemOpenStart(`ui`, `tag`)

    # Attributes
    for node in args:
      case node.kind:
      of nnkStrLit:
        result.add quote do:
          class(`ui`, `node`)
      of nnkExprColonExpr, nnkExprEqExpr:
        if $node[0] != "key":
          let name = newLit($node[0])
          let value = node[1]
          result.add quote do:
            attr(`ui`, `name`, `value`)
      of nnkStmtList:
        discard
      else:
        error("`ui.elem` parameters must be attributes or a body", node)

    # End open
    result.add quote do:
      elemOpenEnd(`ui`)

    # Inside
    if args.len > 0 and args.last.kind == nnkStmtList:
      result.add(args.last)

    # Close
    result.add quote do:
      elemClose(`ui`, `tag`)

    when debug:
      echo "tree: ", result.treeRepr, "\n"
      echo "code: ", result.repr, "\n"


# Common elements

template box*(ui: var UI, args: varargs[untyped]) =
  ## `ui.elem` with the `"div"` tag
  elem(ui, "div", args)

template button*(ui: var UI, args: varargs[untyped]) =
  ## `ui.elem` with the `"button"` tag
  elem(ui, "button", args)


# Text

proc text*(ui: var UI, value: string) {.inline.} =
  ## Add the given text as a child of the enclosing UI element.
  when defined(emscripten):
    proc JS_uiText(value: cstring) {.importc.}
    JS_uiText(value)


# Events

when defined(emscripten):
  proc JS_uiEventCount(typ: cstring): int {.importc.}

template event*(ui: var UI, eventType: string, body: typed) =
  ## Run the body for each occurrence of the named event in the last
  ## UI frame for the enclosing UI element.
  when defined(emscripten):
    block:
      let count = JS_uiEventCount(eventType)
      for i in 1..count:
        body


# Values

proc valueStr*(ui: var UI): string =
  ## Get the value of the current UI element as a string.
  when defined(emscripten):
    proc JS_uiValue(): cstring {.importc.}
    let cStr = JS_uiValue()
    result = $cStr
    proc free(p: pointer) {.importc.}
    free(cStr)

proc valueInt*(ui: var UI): int =
  ## Get the value of the current UI element as an integer.
  when defined(emscripten):
    ui.valueStr.parseInt

proc valueFloat*(ui: var UI): float =
  ## Get the value of the current UI element as a floating point number.
  when defined(emscripten):
    ui.valueStr.parseFloat


# Patch

var thePatchProc: proc()

when defined(emscripten):
  proc JS_uiPatch(id: cstring) {.importc.}

template patch*(ui: var UI, id: cstring, body: typed) =
  ## Display the UI elements in the body at the DOM node with the given ID.
  when defined(emscripten):
    block:
      proc patchProc() =
        body
      thePatchProc = patchProc # Save the patch proc to be called below
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
  ## Run one frame of UI logic. Generally this is done once per event loop
  ## (see the 'events' module). All UI display should be done in the body.
  when defined(emscripten):
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
