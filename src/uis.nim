## Interface to DOM-based user interface in the browser

{.emit: "#include <emscripten.h>"}

import utils

type
  UI = object


# Elements

proc JS_uiElemOpenStart(tag: cstring) {.importc.}
proc JS_uiElemOpenStartKeyInt(tag: cstring, key: int) {.importc.}
proc JS_uiElemOpenStartKeyStr(tag: cstring, key: cstring) {.importc.}

proc JS_uiElemOpenEnd() {.importc.}

proc JS_uiElemClose(tag: cstring) {.importc.}

proc JS_uiAttrInt(name: cstring, value: int) {.importc.}
proc JS_uiAttrFloat(name: cstring, value: float) {.importc.}
proc JS_uiAttrStr(name: cstring, value: cstring) {.importc.}
proc JS_uiAttrClass(class: cstring) {.importc.}

template elem*(ui: var UI,
  tag: string, attrs: openArray[(string, string)], body: typed) =
  JS_uiElemOpenStart(tag)
  for (name, value) in attrs:
    JS_uiAttrStr(name, value)
  JS_uiElemOpenEnd()
  body
  JS_uiElemClose(tag)

template elem*(ui: var UI,
  tag: string, attrs: openArray[(string, string)]) =
  JS_uiElemOpenStart(tag)
  for (name, value) in attrs:
    JS_uiAttrStr(name, value)
  JS_uiElemOpenEnd()
  JS_uiElemClose(tag)

template elem*(ui: var UI, tag: string, body: typed) =
  JS_uiElemOpenStart(tag)
  JS_uiElemOpenEnd()
  body
  JS_uiElemClose(tag)

template elem*(ui: var UI, tag: string) =
  elem(ui, tag):
    discard


# Text

proc JS_uiText(value: cstring) {.importc.}

proc text*(ui: var UI, value: string) {.inline.} =
  JS_uiText(value)


# Patch

proc JS_uiPatch(id: cstring) {.importc.}

var thePatchProc: proc()

template patch*(ui: var UI, id: cstring, body: typed) =
  block:
    proc patchProc() =
      body
    thePatchProc = patchProc
    JS_uiPatch(id)
    thePatchProc = nil

proc JS_uiCallPatchProc()
  {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  if thePatchProc != nil:
    thePatchProc()


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
