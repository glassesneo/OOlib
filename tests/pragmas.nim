discard """
  action: "compile"
"""
import ../src/oolib
import unittest, macros

template customPragma() {.pragma.}

class A {.customPragma.}

check A.hasCustomPragma(customPragma)
