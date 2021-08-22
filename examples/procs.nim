{.experimental: "strictFuncs".}
import oolib


class pub A:
  var
    a: int
    b: seq[string]

  proc increment* =
    inc self.a

  func plusA*(x: int): int = x + self.a

  iterator items*: string =
    for s in self.b:
      yield s

  converter toInt*: int =
    result = self.a
