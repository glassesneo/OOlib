discard """
action: "run"
"""
import ../src/oolib

class pub A:
  var a*: int


class B {.open.}:
  var b, c*: string
