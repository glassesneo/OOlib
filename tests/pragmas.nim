discard """
  action: "compile"
"""
import ../src/oolib
import unittest, macros

template customPragma(v = "") {.pragma.}

class A {.customPragma.}

class B {.customPragma "B".}

check A.hasCustomPragma(customPragma)
check B.getCustomPragmaVal(customPragma) is NimNode
