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
  self.state.defConstructor(info, partOfCtor, argsList)
