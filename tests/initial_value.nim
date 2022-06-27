discard """
  action: "run"
"""
import unittest
import ../src/oolib

class Vector:
  var x {.initial.}, y {.initial.}: uint = 5

let v1 = Vector.new()

check v1.x == 5
check v1.y == 5
