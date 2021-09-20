import sequtils, macros
import .. / util
import .. / classutil
import state_interface

type
  NormalState* = ref object

  InheritanceState* = ref object

  DistinctState* = ref object

  AliasState* = ref object


proc defConstructor(
    self: NormalState,
    info: ClassInfo,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  let node = info.node
  return
    if not info.node.isEmpty:
      node.assistWithDef(
        info,
        argsList.filterIt(it.hasDefault).map rmAsteriskFromIdent
      )
    else:
      info.defNew(argsList.map rmAsteriskFromIdent)


proc toInterface*(self: NormalState): IState {.compileTime.} =
  result = (
    defConstructor:
    proc(info: ClassInfo, argsList: seq[NimNode]): NimNode =
      self.defConstructor(info, argsList)
  )


proc defConstructor(
    self: InheritanceState,
    info: ClassInfo,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  let node = info.node
  return
    if node.isEmpty:
      newEmptyNode()
    else:
      node.assistWithDef(
        info,
        argsList.filterIt(it.hasDefault).map rmAsteriskFromIdent
      )


proc toInterface*(self: InheritanceState): IState {.compileTime.} =
  result = (
    defConstructor:
    proc(info: ClassInfo, argsList: seq[NimNode]): NimNode =
      self.defConstructor(info, argsList)
  )


proc defConstructor(
    self: DistinctState,
    info: ClassInfo,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  return newEmptyNode()


proc toInterface*(self: DistinctState): IState {.compileTime.} =
  result = (
    defConstructor:
    proc(info: ClassInfo, argsList: seq[NimNode]): NimNode =
      self.defConstructor(info, argsList)
  )


proc defConstructor(
    self: AliasState,
    info: ClassInfo,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  return newEmptyNode()


proc toInterface*(self: AliasState): IState {.compileTime.} =
  result = (
    defConstructor:
    proc(info: ClassInfo, argsList: seq[NimNode]): NimNode =
      self.defConstructor(info, argsList)
  )


proc newState*(info: ClassInfo): IState {.compileTime.} =
  result = case info.kind
    of Normal: NormalState().toInterface()
    of Inheritance: InheritanceState().toInterface()
    of Distinct: DistinctState().toInterface()
    of Alias: AliasState().toInterface()
