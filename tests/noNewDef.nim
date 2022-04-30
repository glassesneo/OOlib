discard """
  action: "run"
"""
import unittest
import ../src/oolib

class A {.noNewDef.}:
  var a: int
  var b: string

check not compiles(A.new(1, ""))
