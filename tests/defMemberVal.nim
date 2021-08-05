discard """
  action: "run"
"""
import unittest
import ../src/oolib

class A:
  var
    a: int = 0
    b: string = ""


let
  a = A(a: 5, b: "aa")

check a.a == 5
check a.b == "aa"
