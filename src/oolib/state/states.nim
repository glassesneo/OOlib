import
  std/macros,
  std/sequtils,
  std/sugar,
  .. / util,
  .. / classes,
  .. / tmpl,
  state_interface


func hasAsterisk*(node: NimNode): bool {.compileTime.} =
  node.len > 0 and
  node.kind == nnkPostfix and
  node[0].eqIdent"*"


func rmAsterisk(node: NimNode): NimNode {.compileTime.} =
  result = node
  if node.hasAsterisk:
    result = node[1]


proc rmAsteriskFromIdent(def: NimNode): NimNode {.compileTime.} =
  result = nnkIdentDefs.newNimNode()
  for v in def[0..^3]:
    result.add v.rmAsterisk
  result.add(def[^2], def[^1])


func toRecList(s: seq[NimNode]): NimNode {.compileTime.} =
  result = nnkRecList.newNimNode()
  for def in s:
    result.add def


type
  NormalState* = ref object

  InheritanceState* = ref object

  DistinctState* = ref object

  AliasState* = ref object

  ImplementationState* = ref object


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
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  if "noNewDef" in info.pragmas:
    return
  theClass.insertIn1st(
    if members.ctorBase.isEmpty:
      info.defNew(members.allArgsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase.assistWithDef(
        info,
        members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
      )
  )


proc defMemberVars(
    self: NormalState,
    theClass: NimNode,
    members: ClassMembers
) {.compileTime.} =
  theClass[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()


proc defMemberFuncs(
    self: NormalState,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  discard


proc toInterface*(self: NormalState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberFuncs: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberFuncs(theClass, info, members)

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
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  if not (members.ctorBase.isEmpty or "noNewDef" in info.pragmas):
    theClass.insertIn1st members.ctorBase.assistWithDef(
      info,
      members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
    )


proc defMemberVars(
    self: InheritanceState,
    theClass: NimNode,
    members: ClassMembers
) {.compileTime.} =
  theClass[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()


proc defMemberFuncs(
    self: InheritanceState,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  discard


proc toInterface*(self: InheritanceState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberFuncs: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberFuncs(theClass, info, members)
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
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberVars(
    self: DistinctState,
    theClass: NimNode,
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberFuncs(
    self: DistinctState,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  discard


proc toInterface*(self: DistinctState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberFuncs: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberFuncs(theClass, info, members)


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
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberVars(
    self: AliasState,
    theClass: NimNode,
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberFuncs(
    self: AliasState,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  discard


proc toInterface*(self: AliasState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberFuncs: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberFuncs(theClass, info, members)


  )


proc defClass(
    self: ImplementationState,
    info: ClassInfo
): NimNode {.compileTime.} =
  result = getAst defObj(info.name)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


proc defConstructor(
    self: ImplementationState,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  if "noNewDef" in info.pragmas:
    return
  theClass.insertIn1st(
    if members.ctorBase.isEmpty:
      info.defNew(members.allArgsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase.assistWithDef(
        info,
        members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
      )
  )


proc defMemberVars(
    self: ImplementationState,
    theClass: NimNode,
    members: ClassMembers
) {.compileTime.} =
  theClass[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()


proc defMemberFuncs(
    self: ImplementationState,
    theClass: NimNode,
    info: ClassInfo,
    members: ClassMembers
) {.compileTime.} =
  theClass.add newProc(
    ident"toInterface",
    [info.base],
    newStmtList(
      nnkReturnStmt.newNimNode.add(
        nnkTupleConstr.newNimNode.add(
          members.argsList.decomposeDefsIntoVars().map newVarsColonExpr
    ).add(
        members.body.filterIt(
          it.kind in {nnkProcDef, nnkFuncDef, nnkMethodDef, nnkIteratorDef}
      ).filterIt("ignored" notin it[4]).map newLambdaColonExpr
    )
    )
    )
  ).insertSelf(info.name)


proc toInterface*(self: ImplementationState): IState {.compileTime.} =
  result = (
    defClass: (info: ClassInfo) => self.defClass(info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberFuncs: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberFuncs(theClass, info, members)

  )


proc newState*(info: ClassInfo): IState {.compileTime.} =
  result = case info.kind
    of Normal: NormalState().toInterface()
    of Inheritance: InheritanceState().toInterface()
    of Distinct: DistinctState().toInterface()
    of Alias: AliasState().toInterface()
    of Implementation: ImplementationState().toInterface()
