import .. / classutil

type
  IState* = tuple
    defConstructor: proc(info: ClassInfo, argsList: seq[NimNode]): NimNode
