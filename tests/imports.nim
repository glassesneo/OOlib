discard """
  action: "run"
"""
import ./exports

let
  a {.used.} = newA(1)
  b {.used.} = newB("string")
