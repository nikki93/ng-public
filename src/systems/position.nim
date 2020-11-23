import core

import types, triggers


# Editing

onEditApplyMoves.add proc() =
  for _, move, pos in ker.each(EditMove, Position):
    pos.x += move.dx
    pos.y += move.dy
