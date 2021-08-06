import macros
import util

template genTheNew*(isPub: bool, b: untyped): NimNode =
  block:
    var
      name {.inject.}: NimNode
      params {.inject.}: seq[NimNode]
      body {.inject.}: NimNode
    b
    if isPub:
      newProc(name, params, body).markWithAsterisk()
    else:
      newProc(name, params, body)
