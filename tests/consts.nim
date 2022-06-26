discard """
  action: "run"
"""
import unittest
import ../src/oolib

class pub A {.open.}:
  const common* = "foo"
  const speed* = 10.0f

  var pos: float32 = 0f

  method update(dt: float32) {.base.} =
    self.pos += self.speed

class pub B of A:
  const speed* = 15.0f

  proc `new`(pos = 0f) =
    self.pos = pos

var a = A.new(pos = 5f)
var b = B.new(pos = 10f)

check b.speed > a.speed

check A.common == "foo"
check B.common == "foo"

check a.common == "foo"
check b.common == "foo"

check a.pos == 5f
a.update(1f)
check a.pos == 15f

check b.pos == 10f
b.update(1f)
check b.pos == 25f
