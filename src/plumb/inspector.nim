## Editor entity inspector UI. This is in a separate file so we can import
## 'all' to get type-specific hooks, yet allow types to import the rest of
## 'editing'.

import std/[strutils, json]

import core

import editing

import systems/all


func titleify(title: string): string =
  ## Turn "TitlesYay" into "titles yay"
  for i, c in title:
    if c.isUpperAscii:
      if i > 0:
        result.add(" ")
      result.add(c.toLowerAscii)
    else:
      result.add(c)


proc inspector*(editx: var Edit) =
  ## Top-level entrypoint for the inspector UI

  # Inspectors for selected entities
  for ent, _ in ker.each(EditSelect):
    ui.box("inspector"):
      # Collect procs to run after, preventing UI inconsistencies
      var after: seq[proc()]

      # Section for each type that isn't marked `{.noedit.}`
      forEachRegisteredTypeSkip(T, "noedit"):
        if (let inst = ker.get(T, ent); inst != nil):
          const title = titleify($T)
          ui.elem("details", class = title, key = title, open = true):
            # Header with title and remove button
            ui.elem("summary"):
              ui.text(title)
              ui.button("remove"):
                ui.event("click"):
                  after.add proc() =
                    ker.remove(T, ent)
                    edit.checkpoint("remove " & title)

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
          if not ker.has(T, ent):
            const title = titleify($T)
            ui.button("add", label = title):
              ui.event("click"):
                let inst = ker.add(T, ent)
                when compiles(load(inst[], ent, JsonNode())):
                  # Custom `load` hook
                  load(inst[], ent, JsonNode())
                edit.checkpoint("add " & title)

      # Run after procs
      for p in after:
        p()
