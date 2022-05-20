import
  .. / types,
  state_interface


type
  Context* = ref object
    state: IState


proc newContext*(state: IState): Context {.compileTime.} =
  Context(state: state)


proc getClassMembers*(
    self: Context,
    body: NimNode,
    info: ClassInfo
): ClassMembers {.compileTime.} =
  self.state.getClassMembers(body, info)


proc defClass*(
    self: Context,
    theClass: NimNode,
    info: ClassInfo
) {.compileTime.} =
  self.state.defClass(theClass, info)


proc defBody*(
    self: Context,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  self.state.defBody(theClass, info, members)
