import sequtils, macros, sugar
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
    partOfCtor: NimNode,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  return
    if not partOfCtor.isEmpty:
      partOfCtor.assistWithDef(
        info,
        argsList.filterIt(it.hasDefault).map rmAsteriskFromIdent
      )
    else:
      info.defNew(argsList.map rmAsteriskFromIdent)


proc toInterface*(self: NormalState): IState {.compileTime.} =
  result = (
    defConstructor:
    (info: ClassInfo, partOfCtor: NimNode, argsList: seq[NimNode]) =>
      self.defConstructor(info, partOfCtor, argsList)
  )


proc defConstructor(
    self: InheritanceState,
    info: ClassInfo,
    partOfCtor: NimNode,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  return
    if partOfCtor.isEmpty:
      newEmptyNode()
    else:
      partOfCtor.assistWithDef(
        info,
        argsList.filterIt(it.hasDefault).map rmAsteriskFromIdent
      )


proc toInterface*(self: InheritanceState): IState {.compileTime.} =
  result = (
    defConstructor:
    (info: ClassInfo, partOfCtor: NimNode, argsList: seq[NimNode]) =>
      self.defConstructor(info, partOfCtor, argsList)
  )


proc defConstructor(
    self: DistinctState,
    info: ClassInfo,
    partOfCtor: NimNode,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  return newEmptyNode()


proc toInterface*(self: DistinctState): IState {.compileTime.} =
  result = (
    defConstructor:
    (info: ClassInfo, partOfCtor: NimNode, argsList: seq[NimNode]) =>
      self.defConstructor(info, partOfCtor, argsList)
  )


proc defConstructor(
    self: AliasState,
    info: ClassInfo,
    partOfCtor: NimNode,
    argsList: seq[NimNode]
): NimNode {.compileTime.} =
  return newEmptyNode()


proc toInterface*(self: AliasState): IState {.compileTime.} =
  result = (
    defConstructor:
    (info: ClassInfo, partOfCtor: NimNode, argsList: seq[NimNode]) =>
      self.defConstructor(info, partOfCtor, argsList)
  )


proc newState*(info: ClassInfo): IState {.compileTime.} =
  result = case info.kind
    of Normal: NormalState().toInterface()
    of Inheritance: InheritanceState().toInterface()
    of Distinct: DistinctState().toInterface()
    of Alias: AliasState().toInterface()
