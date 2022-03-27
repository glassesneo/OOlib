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


proc genConstant*(className: string; node: NimNode): NimNode {.compileTime.} =
  # generate both a template for use with typedesc and a method for dynamic dispatch
  #
  # dumpAstGen:
  #   template speed*(self: typedesc[A]): untyped = 10.0f
  #   method speed*(self: A): typeof(10.0f) {.optBase.} = 10.0f

  nnkStmtList.newTree(
    # template
    nnkTemplateDef.newTree(
      node[0],
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        newIdentNode("untyped"),
        newIdentDefs(
          newIdentNode("self"),
          nnkBracketExpr.newTree(
            newIdentNode("typedesc"),
            newIdentNode(className)
      ),
      newEmptyNode()
    )
      ),
      newEmptyNode(),
      newEmptyNode(),
      newStmtList(
        node[^1]
      )
    ),
    # method
    nnkMethodDef.newTree(
      node[0],
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        node[1],
        newIdentDefs(
          newIdentNode("self"),
          newIdentNode(className),
          newEmptyNode(),
      )
    ),
      nnkPragma.newTree(
        newIdentNode("optBase")
      ),
      newEmptyNode(),
      newStmtList(
        nnkReturnStmt.newTree(
          node[^1]
        )
      )
    ),
  )


type
  NormalState* = ref object

  InheritanceState* = ref object

  DistinctState* = ref object

  AliasState* = ref object

  ImplementationState* = ref object


proc defClass(
    self: NormalState;
    theClass: NimNode;
    info: ClassInfo
) {.compileTime.} =
  theClass.add(getAst defObj(info.name))
  if info.isPub:
    markWithPostfix(theClass[0][0][0])
  if "open" in info.pragmas:
    theClass[0][0][2][0][1] = nnkOfInherit.newTree ident"RootObj"
  newPragmaExpr(theClass[0][0][0], "pClass")


proc defConstructor(
    self: NormalState;
    theClass: NimNode;
    info: ClassInfo;
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
    self: NormalState;
    theClass: NimNode;
    members: ClassMembers
) {.compileTime.} =
  theClass[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()


proc defMemberRoutines(
    self: NormalState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  for c in members.constsList:
    theClass.insertIn1st genConstant(info.name.strVal, c)


proc toInterface*(self: NormalState): IState {.compileTime.} =
  result = (
    defClass: (theClass: NimNode, info: ClassInfo) => self.defClass(theClass, info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberRoutines: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberRoutines(theClass, info, members)

  )


proc defClass(
    self: InheritanceState;
    theClass: NimNode;
    info: ClassInfo
) {.compileTime.} =
  theClass.add getAst defObjWithBase(info.name, info.base)
  if info.isPub:
    markWithPostfix(theClass[0][0][0])
  newPragmaExpr(theClass[0][0][0], "pClass")


proc defConstructor(
    self: InheritanceState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  if not (members.ctorBase.isEmpty or "noNewDef" in info.pragmas):
    theClass.insertIn1st members.ctorBase.assistWithDef(
      info,
      members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
    )


proc defMemberVars(
    self: InheritanceState;
    theClass: NimNode;
    members: ClassMembers
) {.compileTime.} =
  theClass[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()


proc defMemberRoutines(
    self: InheritanceState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  for c in members.constsList:
    theClass.insertIn1st genConstant(info.name.strVal, c)


proc toInterface*(self: InheritanceState): IState {.compileTime.} =
  result = (
    defClass: (theClass: NimNode, info: ClassInfo) => self.defClass(theClass, info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberRoutines: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberRoutines(theClass, info, members)
  )


proc defClass(
    self: DistinctState;
    theClass: NimNode;
    info: ClassInfo
) {.compileTime.} =
  theClass.add getAst defDistinct(info.name, info.base)
  if info.isPub:
    markWithPostfix(theClass[0][0][0][0])
  if "open" in info.pragmas:
    # replace {.final.} with {.inheritable.}
    theClass[0][0][0][1][0] = ident "inheritable"
    theClass[0][0][0][1].add ident "pClass"


proc defConstructor(
    self: DistinctState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberVars(
    self: DistinctState;
    theClass: NimNode;
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberRoutines(
    self: DistinctState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  for c in members.constsList:
    theClass.insertIn1st genConstant(info.name.strVal, c)


proc toInterface*(self: DistinctState): IState {.compileTime.} =
  result = (
    defClass: (theClass: NimNode, info: ClassInfo) => self.defClass(theClass, info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberRoutines: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberRoutines(theClass, info, members)


  )


proc defClass(
    self: AliasState;
    theClass: NimNode;
    info: ClassInfo
) {.compileTime.} =
  theClass.add getAst defAlias(info.name, info.base)
  if info.isPub:
    markWithPostfix(theClass[0][0][0])
  newPragmaExpr(theClass[0][0][0], "pClass")


proc defConstructor(
    self: AliasState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberVars(
    self: AliasState;
    theClass: NimNode;
    members: ClassMembers
) {.compileTime.} =
  discard


proc defMemberRoutines(
    self: AliasState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  for c in members.constsList:
    theClass.insertIn1st genConstant(info.name.strVal, c)


proc toInterface*(self: AliasState): IState {.compileTime.} =
  result = (
    defClass: (theClass: NimNode, info: ClassInfo) => self.defClass(theClass, info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberRoutines: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberRoutines(theClass, info, members)


  )


proc defClass(
    self: ImplementationState;
    theClass: NimNode;
    info: ClassInfo
) {.compileTime.} =
  theClass.add getAst defObj(info.name)
  if info.isPub:
    markWithPostfix(theClass[0][0][0])
  newPragmaExpr(theClass[0][0][0], "pClass")


proc defConstructor(
    self: ImplementationState;
    theClass: NimNode;
    info: ClassInfo;
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
    self: ImplementationState;
    theClass: NimNode;
    members: ClassMembers
) {.compileTime.} =
  theClass[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()


proc defMemberRoutines(
    self: ImplementationState;
    theClass: NimNode;
    info: ClassInfo;
    members: ClassMembers
) {.compileTime.} =
  for c in members.constsList:
    theClass.insertIn1st genConstant(info.name.strVal, c)
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
    defClass: (theClass: NimNode, info: ClassInfo) => self.defClass(theClass, info),
    defConstructor:
    (theClass: NimNode, info: ClassInfo, members: ClassMembers) =>
      self.defConstructor(theClass, info, members),
    defMemberVars: (theClass: NimNode, members: ClassMembers) =>
      self.defMemberVars(theClass, members),
    defMemberRoutines: (theClass: NimNode, info: ClassInfo,
        members: ClassMembers) =>
      self.defMemberRoutines(theClass, info, members)

  )


proc newState*(info: ClassInfo): IState {.compileTime.} =
  result = case info.kind
    of Normal: NormalState().toInterface()
    of Inheritance: InheritanceState().toInterface()
    of Distinct: DistinctState().toInterface()
    of Alias: AliasState().toInterface()
    of Implementation: ImplementationState().toInterface()
