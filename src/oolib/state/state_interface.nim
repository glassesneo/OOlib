import
  .. / types


type
  IState* = tuple
    getClassMembers: proc(body: NimNode, info: ClassInfo): ClassMembers
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
