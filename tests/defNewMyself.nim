discard """
  action: "run"
"""
import unittest
import ../src/oolib

class A:
  var
    a: int
    b: string

  proc `new`(someInt: int) =
    self.a = someInt
    self.b = $someInt

class B:
  var
    c, d = ""
    e: bool

  proc `new` =
    self.e = (self.c == self.d)


let
  a = newA(2)
  b1 = newB()
  b2 = newB(c = "aaa")
  b3 = newB(d = "bbb")


check a.a == 2 and a.b == "2"
check b1.c == "" and b1.d == ""
check b1.e
check b2.c == "aaa"
check not b2.e
check b3.d == "bbb"
check not b3.e
