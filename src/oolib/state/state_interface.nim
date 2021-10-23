import sugar
import .. / classutil


type
  IState* = tuple
    defClass: (info: ClassInfo) -> NimNode
    defConstructor: (
      info: ClassInfo, members: ClassMembers
    ) -> NimNode
