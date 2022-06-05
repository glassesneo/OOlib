import
  std/sugar,
  .. / types


type
  IState* = tuple
    data: ClassData
    getClassData: (body: NimNode) -> void
    defClass: () -> NimNode
    defConstructor: (theClass: NimNode) -> void
    defMemberVars: (theClass: NimNode) -> void
    defMemberRoutines: (theClass: NimNode) -> void
    defBody: (theClass: NimNode) -> void
