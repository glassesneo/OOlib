import
  .. / classes,
  state_interface


type
  Context* = ref object
    state: IState


proc newContext*(state: IState): Context {.compileTime.} =
  Context(state: state)


proc defClass*(
    self: Context,
    theClass: NimNode,
    info: ClassInfo
) {.compileTime.} =
  self.state.defClass(theClass, info)


proc defConstructor*(
    self: Context,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  self.state.defConstructor(theClass, info, members)


proc defMemberVars*(
    self: Context,
    theClass: NimNode,
    members: ClassMembers
) {.compileTime.} =
  self.state.defMemberVars(theClass, members)


proc defMemberRoutines*(
    self: Context,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  self.state.defMemberRoutines(theClass, info, members)
