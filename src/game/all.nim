## This is the module to import at the top of all other game modules. We
## organize things this way so that import order is clear and type-specific
## hooks are visible in modules that need them (eg. `load` being needed by
## 'saveload'). All modules should be listed here in dependency order.


import math, json, strutils
export math, json, strutils


import ng
export ng


import types
export types

import triggers
export triggers

import sprite, feet, player
export sprite, feet, player


import saveload
export saveload
