discard """
  action: "run"
"""
import unittest
import ../src/oolib

class A

let a = A.new()

check a.isClass()

class pub B:
  var val1: int
  var val2: string

let b = B.new(2, "2")

check b.val1 == 2
check b.val2 == "2"

class C {.open.}:
  var val1: bool
  var val2: int = 5

let
  c1 = C.new(false)
  c2 = C.new(true, 4)

check not c1.val1
check c1.val2 == 5
check c2.val1
check c2.val2 == 4

class D:
  var val1: int = 111
  var val2: string = ""
  var val3: bool
  proc `new`() =
    self.val1 = val1
    self.val2 = val2
    self.val3 = $self.val1 == self.val2

let
  d1 = D.new()
  d2 = D.new(3, "3")

check d1.val1 == 111
check d1.val2 == ""
check not d1.val3
check d2.val1 == 3
check d2.val2 == "3"
check d2.val3

class E of C:
  var val3: bool
  proc `new`(val1: bool, val2: int = 5) =
    self.val1 = val1
    self.val2 = val2
    self.val3 = not self.val1

let
  e1 = E.new(false)
  e2 = E.new(true, 4)

check not e1.val1
check e1.val2 == 5
check e1.val3
check e2.val1
check e2.val2 == 4
check not e2.val3
