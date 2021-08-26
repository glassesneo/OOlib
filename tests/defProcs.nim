discard """
  action: "run"
  output: '''
A
6
6
6
6
6
6
6
B
0
'''
"""
import ../src/oolib

class pub A {.open.}:
  var n: int

  proc `$`*: string = "A"

  proc inc* = inc self.n

  method echoN* {.base.} =
    echo self.n

  func returnN*: int = self.n

  template loopNTimes*(body: untyped) =
    for i in 0..<self.n:
      body

class pub B of A:
  proc `new`(n: int) =
    self.n = n
  proc `$`*: string = "B"

  method echoN* =
    procCall A(self).echoN()


let a = newA(5)
echo $a
a.inc
a.echoN()
a.loopNTimes:
  echo a.returnN

let b = newB(5)
echo $b
b.echoN()
