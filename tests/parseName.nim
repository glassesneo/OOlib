discard """
  action: "compile"
"""
import ../src/oolib

class A {.open.}:
  discard

class pub B:
  discard

class C of A:
  discard

class D(distinct B):
  discard

class pub E of C:
  discard

class pub F(distinct D):
  discard
