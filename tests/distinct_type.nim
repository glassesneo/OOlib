discard """
  action: "compile"
"""

import
  ../src/oolib

class Dollar(distinct int):
  proc `+`(other: Dollar): Dollar {.borrow, used.}
  proc `-`(other: Dollar): Dollar {.borrow, used.}

var myMoney {.used.} = 12.Dollar
