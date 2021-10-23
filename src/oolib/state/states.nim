import sequtils, macros, sugar
import .. / util
import .. / classutil
import .. / tmpl
import state_interface


type
  NormalState* = ref object

  InheritanceState* = ref object

  DistinctState* = ref object

  AliasState* = ref object


proc defClass(
    self: NormalState,
    info: ClassInfo
): NimNode {.compileTime.} =
  result = getAst defObj(info.name)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  if "open" in info.pragmas:
    result[0][2][0][1] = nnkOfInherit.newTree ident"RootObj"
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


proc defConstructor(
    self: NormalState,
    info: ClassInfo,
    members: ClassMembers
): NimNode {.compileTime.} =
  result =
    if members.ctorBase.isEmpty:
      info.defNew(members.argsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase.assistWithDef(
        info,
        members.argsList.filterIt(it.hasDefault).map rmAsteriskFromIdent
      )


proc toInterface*(self: NormalState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(info, members)
  )


proc defClass(
    self: InheritanceState,
    info: ClassInfo
): NimNode {.compileTime.} =
  result = getAst defObjWithBase(info.name, info.base)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


proc defConstructor(
    self: InheritanceState,
    info: ClassInfo,
    members: ClassMembers
): NimNode {.compileTime.} =
  return
    if members.ctorBase.isEmpty:
      newEmptyNode()
    else:
      members.ctorBase.assistWithDef(
        info,
        members.argsList.filterIt(it.hasDefault).map rmAsteriskFromIdent
      )


proc toInterface*(self: InheritanceState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(info, members)
  )


proc defClass(
    self: DistinctState,
    info: ClassInfo
): NimNode {.compileTime.} =
  result = getAst defDistinct(info.name, info.base)
  if info.isPub:
    result[0][0][0] = newPostfix(result[0][0][0])
  if "open" in info.pragmas:
    # replace {.final.} with {.inheritable.}
    result[0][0][1][0] = ident "inheritable"
    result[0][0][1].add ident "pClass"


proc defConstructor(
    self: DistinctState,
    info: ClassInfo,
    members: ClassMembers
): NimNode {.compileTime.} =
  return newEmptyNode()


proc toInterface*(self: DistinctState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(info, members)
  )


proc defClass(
    self: AliasState,
    info: ClassInfo
): NimNode {.compileTime.} =
  result = getAst defAlias(info.name, info.base)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


proc defConstructor(
    self: AliasState,
    info: ClassInfo,
    members: ClassMembers
): NimNode {.compileTime.} =
  return newEmptyNode()


proc toInterface*(self: AliasState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(info, members)
  )


proc newState*(info: ClassInfo): IState {.compileTime.} =
  result = case info.kind
    of Normal: NormalState().toInterface()
    of Inheritance: InheritanceState().toInterface()
    of Distinct: DistinctState().toInterface()
    of Alias: AliasState().toInterface()
