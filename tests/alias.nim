discard """
  action: "run"
"""
import ../src/oolib
import unittest

class MyInt(int):
  discard

class MyString(string):
  discard

class MyNumber(int | float):
  discard

let
  myInt: MyInt = 1
  myStr: MyString = "foo"
  myNum1: MyNumber = 2
  myNum2: MyNumber = 0.2

check(myInt is int)
check(myStr is string)
check(myNum1 is int)
check(myNum2 is float)
