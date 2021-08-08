discard """
  action: "compile"
"""
import ../src/classes

class A:
  var a: int
  var b: string

class B:
  var c, d: float

class C:
  var
    e: bool
    f, g: seq[int]
