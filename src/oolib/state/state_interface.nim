import
  .. / types


type
  IState* = tuple
    data: ClassData
    getClassMembers: proc(body: NimNode)
    defClass: proc(theClass: NimNode)
    defConstructor: proc(theClass: NimNode)
    defMemberVars: proc(theClass: NimNode)
    defMemberRoutines: proc(theClass: NimNode)
    defBody: proc(theClass: NimNode)
