import sugar
import .. / classutil

type
  IState* = tuple
    defConstructor: (info: ClassInfo, argsList: seq[NimNode]) -> NimNode
