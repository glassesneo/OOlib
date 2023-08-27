discard """
  action: "compile"
"""

import
  ../src/oolib

protocol pub IA:
  var v: string
  proc wow
  proc f(v1: int, v2: int): int

protocol IB:
  var isOK: bool
  var wtf: int

class A impl (IA, IB):
  var v = ""
  var wtf {.initial.} = 0
  var isOK: bool
  proc wow {.used.} =
    echo "wow"

  proc f(v1, v2: int): int {.used.} =
    result = v1 + v2

  proc f2 {.used.} =
    echo "f2"

let a = A.new("aa", true)

let _ = a.toProtocol()

type IC* {.protocoled.} = tuple
  f: proc(x: int): int

class B impl IC:
  proc f(x: int): int = x*x
