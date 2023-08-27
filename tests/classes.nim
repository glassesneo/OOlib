discard """
  action: "compile"
"""

import
  ../src/oolib

class A

class B:
  discard

class pub C

class D:
  var
    a*, b: int
    c*: string
  var d: bool

class E:
  var e: int
  proc f {.used.} =
    echo self.e
