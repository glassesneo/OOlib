import
  .. / classes


type
  IState* = tuple
    defClass: proc(theClass: NimNode, info: ClassInfo)
    defConstructor: proc(
      theClass: NimNode, info: ClassInfo, members: ClassMembers
    )
    defMemberVars: proc(
      theClass: NimNode, members: ClassMembers
    )
    defMemberRoutines: proc(
      theClass: NimNode, info: ClassInfo, members: ClassMembers
    )
