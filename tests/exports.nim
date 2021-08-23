discard """
action: "run"
"""
import ../src/oolib

class pub A:
  var a*: int


class pub B:
  var b, c*: string

  proc `new`(str: string) =
    self.b = str
    self.c = str
