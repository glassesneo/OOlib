discard """
  action: "compile"
"""
import unittest
import ../src/oolib

protocol IA:
  proc a()
  proc b(x: int, y: string): bool

protocol IB:
  proc c(op: proc(x, y: int): int)

protocol IC:
  proc d()
  func e()

check IA is tuple[a: proc, b: proc(x: int, y: string): bool]
check IB is tuple[c: proc(op: proc(x, y: int): int)]
check IC is tuple[d: proc, e: proc {.noSideEffect.}]
