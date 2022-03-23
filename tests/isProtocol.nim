discard """
  action: "run"
"""
import ../src/oolib
import unittest, macros


protocol IA:
  var val1: int

type IB = tuple
  val2: int

let
  a {.used.}: IA = (val1: 1)
  b {.used.}: IB = (val2: 1)

check IA.isProtocol()
check a.isProtocol()
check not IB.isProtocol()
check not b.hasCustomPragma(pProtocol)
