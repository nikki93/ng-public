## Implementation of the editor UI. This is in a separate file so we can import
## 'all' for type-specific hooks.

import std/[strutils, json]

import ng

import editing, all


# UI

proc toolbar*(edit: var Edit) =
  # Play / stop
  ui.button(class = if edit.isEnabled: "play" else: "stop"):
    ui.event("click"):
      if edit.isEnabled:
        edit.play()
      else:
        edit.stop()

  ui.box("flex-gap")

  if edit.isEnabled:
    # Pan
    ui.button("view pan", selected = edit.getMode == "view pan"):
      ui.event("click"):
        edit.setMode(if edit.getMode == "view pan": "select" else: "view pan")

proc status*(edit: var Edit) =
  if edit.isEnabled:
    ui.box: # Zoom level
      let (_, _, vw, _) = edit.getView
      ui.text vw / 800, "x"

    ui.box("small-gap")

    ui.box: # Mode
      ui.text edit.getMode

func titleify(title: string): string =
  ## Turn "TitlesYay" into "titles yay"
  for i, c in title:
    if c.isUpperAscii:
      if i > 0:
        result.add(" ")
      result.add(c.toLowerAscii)
    else:
      result.add(c)

proc inspector*(edit: var Edit) =
  # Inspectors for selected entities
  for ent, _ in ker.each(EditSelect):
    ui.box("inspector"):
      # Collect procs to run after, preventing UI inconsistencies
      var after: seq[proc()]

      # Section for each type that isn't marked `{.noedit.}`
      forEachRegisteredTypeSkip(T, "noedit"):
        let inst = ker.get(T, ent)
        if inst != nil:
          const title = titleify($T)
          ui.elem("details", class = title, key = title, open = true):
            # Header with title and remove button
            ui.elem("summary"):
              ui.text(title)
              ui.button("remove"):
                ui.event("click"):
                  after.add proc() =
                    ker.remove(T, ent)

            # Custom `inspect` hook
            when compiles(inspect(inst[], ent)):
              inspect(inst[], ent)

            # Simple fields
            for name, value in fieldPairs(inst[]):
              when value is SomeFloat:
                ui.box("info"):
                  let valueStr = value.formatFloat(ffDecimal, precision = 2)
                  ui.text name, ": ", valueStr

      # Add button for each type the entity doesn't have
      ui.box("add-bar"):
        forEachRegisteredTypeSkip(T, "noedit"):
          if ker.get(T, ent) == nil:
            const title = titleify($T)
            ui.button("add", label = title):
              ui.event("click"):
                let inst = ker.add(T, ent)
                # Custom `load` hook
                when compiles(load(inst[], ent, JsonNode())):
                  load(inst[], ent, JsonNode())

      # Run after procs
      for p in after:
        p()
