## Imports and re-exports all system modules

import types
export types

template system(ident: untyped) =
  import ident
  export ident

system sprite
system feet
system player
system view_follow
