discard """
  action: "compile"
"""
import ../src/oolib

class pub A:
  var n: int

  proc `$`*: string = "A"

  proc inc* = inc self.n

  method echoN* {.base.} =
    echo self.n

  func returnN*: int = self.n

  template loopNTimes*(body: untyped) =
    for i in 0..<self.n:
      body
