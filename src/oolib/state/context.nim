import macros
import .. / classutil
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
    info: ClassInfo,
    members: ClassMembers
): NimNode {.compileTime.} =
  if "noNewDef" in info.pragmas:
    return newEmptyNode()
  self.state.defConstructor(info, members)
