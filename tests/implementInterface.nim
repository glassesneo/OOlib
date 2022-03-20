discard """
  action: "run"
"""
import ../src/oolib

protocol IA:
  var val1: int
  var val2: string
  proc a()

protocol IB:
  var f1: proc(a: int)
  proc b(a: int, b: string)
  func c(aa: int): int

class A impl IA:
  var val1: int
  var val2: string = "bbb"
  proc a() = echo "aaa"

class B impl IB:
  var f1: proc(a: int)
  proc b(a: int, b: string) =
    for _ in 0..<a: echo b

  func c(aa: int): int = aa + 1

let
  a1 = newA(4, "aa")
  a2 = newA(3)
  b1 = newB(proc(a: int) = echo a)
  b2 = newB(proc(a: int) = echo a + 1)

let
  implementedA1* = a1.toInterface()
  implementedA2* = a2.toInterface()
  implementedB1* = b1.toInterface()
  implementedB2* = b2.toInterface()