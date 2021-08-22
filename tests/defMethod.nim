discard """
  action: "run"
  output: '''
abstract!
abstract!
concrete!
'''
"""
import ../src/oolib

class A {.open.}:
  method sampleMethod {.base.} =
    echo "abstract!"


class B of A:
  method sampleMethod =
    super.sampleMethod()
    echo "concrete!"


let a = newA()
let b = newB()

a.sampleMethod()
b.sampleMethod()
