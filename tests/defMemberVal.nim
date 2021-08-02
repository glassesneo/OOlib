discard """
  action: "compile"
"""
import ../src/classes

class A:
  var
    a: int = 0
    b: string = ""

class B:
  var c: bool
  var d: bool = true

class C:
  var e: float
  var f, g: seq[string] = @["", ""]
