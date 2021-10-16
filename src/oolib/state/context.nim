import macros
import .. / classutil
import state_interface


type
  Context* = ref object
    state: IState


proc newContext*(state: IState): Context {.compileTime.} =
  Context(state: state)


proc defConstructor*(
    self: Context,
    info: ClassInfo,
    partOfCtor: NimNode,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  if "noNewDef" in info.pragmas:
    return newEmptyNode()
  self.state.defConstructor(info, partOfCtor, argsList)
