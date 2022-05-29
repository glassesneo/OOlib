import
  state_interface


type
  Context* = ref object
    state: IState


proc getClassData(
    self: Context,
    body: NimNode,
) {.compileTime.} =
  self.state.getClassData(body)


proc newContext*(state: IState, body: NimNode): Context {.compileTime.} =
  result = Context(state: state)
  result.getClassData(body)


proc defClass*(
    self: Context
): NimNode {.compileTime.} =
  self.state.defClass()


proc defBody*(
    self: Context,
    theClass: NimNode,
) {.compileTime.} =
  self.state.defBody(theClass)
