import macros
import .. / classes
import state_interface


type
  Context* = ref object
    state: IState


proc newContext*(state: IState): Context {.compileTime.} =
  Context(state: state)


proc defClass*(self: Context, info: ClassInfo): NimNode {.compileTime.} =
  newStmtList self.state.defClass(info)


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


proc defMemberFuncs*(
    self: Context,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  self.state.defMemberFuncs(theClass, info, members)
