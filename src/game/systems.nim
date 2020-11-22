## Imports and re-exports all modules that register hooks or triggers

import types
export types

template system(ident: untyped) =
  import ident
  export ident

system sprite
system feet
system player
