discard """
  action: "run"
"""
import unittest
import ../src/oolib

class A:
  var
    a: int
    b: string
    c = "hello"
    d = proc(): string =
      return "default"


let
  a = A(a: 5, b: "aa", c: "goodbye")
  b = newA(a = 5, b = "aa")

check a.a == 5
check a.b == "aa"
check a.c == "goodbye"
check a.d == nil

check b.a == 5
check b.b == "aa"
check b.c == "hello"
check b.d() == "default"
