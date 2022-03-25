import
  std/sugar,
  .. / classes


type
  IState* = tuple
    defClass: (info: ClassInfo) -> NimNode
    defConstructor: proc(
      theClass: NimNode, info: ClassInfo, members: ClassMembers
    )
    defMemberVars: proc(
      theClass: NimNode, members: ClassMembers
    )
    defMemberFuncs: proc(
      theClass: NimNode, info: ClassInfo, members: ClassMembers
    )
