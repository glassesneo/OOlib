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
) {.compileTime.} =
  self.state.getClassMembers(body)


proc defClass*(
    self: Context,
    theClass: NimNode,
) {.compileTime.} =
  self.state.defClass(theClass)


proc defBody*(
    self: Context,
    theClass: NimNode,
) {.compileTime.} =
  self.state.defBody(theClass)
