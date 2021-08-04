discard """
  action: "run"
"""
import ../src/oolib

class A:
  method abstractMethod {.base.}

let a = newA()

a.abstractMethod()
