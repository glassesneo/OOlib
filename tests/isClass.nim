discard """
  action: "run"
"""
import ../src/oolib
import unittest

class A

type B = ref object

let
  a {.used.} = new A
  b {.used.} = new B

check A.isClass()
check a.isClass()
check not B.isClass()
check not b.isClass()
