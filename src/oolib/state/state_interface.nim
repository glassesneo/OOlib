import sugar
import .. / classutil

type
  IState* = tuple
    defConstructor: (
      info: ClassInfo, partOfCtor: NimNode, argsList: seq[NimNode]
    ) -> NimNode
