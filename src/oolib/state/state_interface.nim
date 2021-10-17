import sugar
import .. / classutil


type
  IState* = tuple
    defClass: (info: ClassInfo) -> NimNode
    defConstructor: (
      info: ClassInfo, partOfCtor: NimNode, argsList: seq[NimNode]
    ) -> NimNode
