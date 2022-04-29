discard """
  action: "run"
"""
import ../src/oolib

class A[T]:

  proc f1[T](s: seq[T]) =
    for i in s:
      echo i

let a1 = A[int].new()
let a2 = A[string].new()

a1.f1 @[4, 2, 4]
a2.f1 @["a", "b"]
