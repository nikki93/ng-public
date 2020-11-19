import std/[strutils, json]

import ng

import all, editing


# UI

proc toolbar*(edit: var Edit) =
  # Play / stop
  ui.button(class = if edit.isEnabled: "play" else: "stop"):
    ui.event("click"):
      if edit.isEnabled:
        edit.play()
      else:
        edit.stop()

proc status*(edit: var Edit) =
  discard

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

            # TODO(nikki): Custom inspect

            # Simple fields
            for name, value in fieldPairs(inst[]):
              when value is SomeFloat:
                ui.box("info"):
                  let valueStr = value.formatFloat(ffDecimal, precision = 2)
                  ui.text(name & ": " & valueStr)

      # Add button for each type the entity doesn't have
      ui.box("add-bar"):
        forEachRegisteredTypeSkip(T, "noedit"):
          if ker.get(T, ent) == nil:
            const title = titleify($T)
            ui.button("add", label = title):
              ui.event("click"):
                let inst = ker.add(T, ent)
                when compiles(load(inst[], ent, JsonNode())):
                  load(inst[], ent, JsonNode())

      # Run after procs
      for p in after:
        p()
