import
  state_interface

type
  Context* = ref object
    state: IState

proc newContext*(state: IState): Context {.compileTime.} =
  result = Context(state: state)

proc getClassData*(
    self: Context,
    body: NimNode,
) {.compileTime.} =
  self.state.getClassData(body)

proc defClass*(
    self: Context
): NimNode {.compileTime.} =
  self.state.defClass()

proc defBody*(
    self: Context,
    theClass: NimNode,
) {.compileTime.} =
  self.state.defBody(theClass)
