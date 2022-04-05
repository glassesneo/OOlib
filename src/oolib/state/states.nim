import
  std/macros,
  std/sequtils,
  std/sugar,
  .. / util,
  .. / classes,
  .. / tmpl,
  state_interface


func hasAsterisk*(node: NimNode): bool {.compileTime.} =
  node.kind == nnkPostfix and node[0].eqIdent"*"


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
  ## Generates both a template for use with typedesc and a method for dynamic dispatch.
  # dumpAstGen:
  #   template speed*(self: typedesc[A]): untyped = 10.0f
  #   method speed*(self: A): typeof(10.0f) {.optBase.} = 10.0f

  newStmtList(
    # template
    nnkTemplateDef.newTree(
      node[0],
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        ident"untyped",
        newIdentDefs(
          ident"self",
          nnkBracketExpr.newTree(
            ident"typedesc",
            ident className
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
          ident"self",
          ident className,
          newEmptyNode(),
      )
    ),
      nnkPragma.newTree(
        ident"optBase"
      ),
      newEmptyNode(),
      newStmtList(
        nnkReturnStmt.newTree(
          node[^1]
        )
      )
    ),
  )


func isEmpty*(node: NimNode): bool {.compileTime.} =
  node.kind == nnkEmpty


func hasDefault*(node: NimNode): bool {.compileTime.} =
  ## `node` has to be `nnkIdentDefs` or `nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  not node.last.isEmpty


func insertSelf*(theProc, typeName: NimNode): NimNode {.compileTime.} =
  ## Inserts `self: typeName` in the 1st of theProc.params.
  result = theProc
  result.params.insert 1, newIdentDefs(ident "self", typeName)


func inferValType(node: NimNode) {.compileTime.} =
  ## Infers type from default if a type annotation is empty.
  ## `node` has to be `nnkIdentDefs` or `nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[^2] = node[^2] or newCall(ident"typeof", node[^1])


func isConstructor(node: NimNode): bool {.compileTime.} =
  ## `node` has to be `nnkProcDef`.
  node.expectKind {nnkProcDef}
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func hasPragma(node: NimNode): bool {.compileTime.} =
  ## `node` has to be `nnkIdentDefs or nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[0].kind == nnkPragmaExpr


func newSuperStmt(baseName: NimNode): NimNode {.compileTime.} =
  ## Generates `var super = Base(self)`.
  newVarStmt ident"super", newCall(baseName, ident "self")


func insertSuperStmt(theProc, baseName: NimNode): NimNode {.compileTime.} =
  ## Inserts `var super = Base(self)` in the 1st line of `theProc.body`.
  result = theProc
  result.body.insert 0, newSuperStmt(baseName)


type
  NormalState* = ref object

  InheritanceState* = ref object

  DistinctState* = ref object

  AliasState* = ref object

  ImplementationState* = ref object


proc getClassMembers(
  self: NormalState;
  body: NimNode;
  info: ClassInfo
): ClassMembers {.compileTime.} =
  result.body = newStmtList()
  result.ctorBase = newEmptyNode()
  result.ctorBase2 = newEmptyNode()
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if "noNewDef" in info.pragmas and n.hasDefault:
          error "default values cannot be used with {.noNewDef.}", n
        n.inferValType()
        if n.hasPragma and "ignored" in n[0][1]:
          error "{.ignored.} pragma cannot be used in non-implemented classes"
        result.argsList.add n
    of nnkConstSection:
      for n in node:
        n.inferValType()
        if not n.hasDefault:
          error "A constant must have a value", node
        result.constsList.add n
    of nnkProcDef:
      if node.isConstructor:
        if result.ctorBase.isEmpty:
          result.ctorBase = node.copy()
          result.ctorBase[4] = nnkPragma.newTree(
            newColonExpr(ident"deprecated", newLit"Use Type.new instead")
          )
          result.ctorBase2 = node.copy()
        else:
          error "Constructor already exists", node
      else:
        result.body.add node.insertSelf(info.name)
    of nnkMethodDef, nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.body.add node.insertSelf(info.name)
    else:
      discard


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
  theClass.insert(
    1,
    if members.ctorBase.isEmpty:
      info.defOldNew(members.allArgsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase.assistWithOldDef(
        info,
        members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
      )
  )
  theClass.insert(
    1,
    if members.ctorBase2.isEmpty:
      info.defNew(members.allArgsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase2.assistWithDef(
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
    theClass.insert 1, genConstant(info.name.strVal, c)


proc toInterface*(self: NormalState): IState {.compileTime.} =
  result = (
    getClassMembers:
    (body: NimNode, info: ClassInfo) => self.getClassMembers(body, info),
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


proc getClassMembers(
  self: InheritanceState;
  body: NimNode;
  info: ClassInfo
): ClassMembers {.compileTime.} =
  result.body = newStmtList()
  result.ctorBase = newEmptyNode()
  result.ctorBase2 = newEmptyNode()
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if "noNewDef" in info.pragmas and n.hasDefault:
          error "default values cannot be used with {.noNewDef.}", n
        if n.hasPragma and "ignored" in n[0][1]:
          error "{.ignored.} pragma cannot be used in non-implemented classes"
        n.inferValType()
        result.argsList.add n
    of nnkConstSection:
      for n in node:
        n.inferValType()
        if not n.hasDefault:
          error "A constant must have a value", node
        result.constsList.add n
    of nnkProcDef:
      if node.isConstructor:
        if result.ctorBase.isEmpty:
          result.ctorBase = node.copy()
          result.ctorBase[4] = nnkPragma.newTree(
            newColonExpr(ident"deprecated", newLit"Use Type.new instead")
          )
          result.ctorBase2 = node.copy()
        else:
          error "Constructor already exists", node
      else:
        result.body.add node.insertSelf(info.name)
    of nnkMethodDef:
      node.body = replaceSuper(node.body)
      result.body.add node.insertSelf(info.name).insertSuperStmt(info.base)
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.body.add node.insertSelf(info.name)
    else:
      discard


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
    theClass.insert 1, members.ctorBase.assistWithOldDef(
      info,
      members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
    )
    theClass.insert 1, members.ctorBase2.assistWithDef(
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
    theClass.insert 1, genConstant(info.name.strVal, c)


proc toInterface*(self: InheritanceState): IState {.compileTime.} =
  result = (
    getClassMembers:
    (body: NimNode, info: ClassInfo) => self.getClassMembers(body, info),
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


proc getClassMembers(
  self: DistinctState;
  body: NimNode;
  info: ClassInfo
): ClassMembers {.compileTime.} =
  result.body = newStmtList()
  for node in body:
    case node.kind
    of nnkVarSection:
      error "Distinct type cannot have variables", node
    of nnkConstSection:
      for n in node:
        if not n.hasDefault:
          error "A constant must have a value", node
        n.inferValType()
        result.constsList.add n
    of nnkProcDef, nnkMethodDef, nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.body.add node.insertSelf(info.name)
    else:
      discard


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
    theClass.insert 1, genConstant(info.name.strVal, c)


proc toInterface*(self: DistinctState): IState {.compileTime.} =
  result = (
    getClassMembers:
    (body: NimNode, info: ClassInfo) => self.getClassMembers(body, info),
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


proc getClassMembers(
  self: AliasState;
  body: NimNode;
  info: ClassInfo
): ClassMembers {.compileTime.} =
  result.body = newStmtList()
  for node in body:
    case node.kind
    of nnkVarSection:
      error "Type alias cannot have variables", node
    of nnkConstSection:
      for n in node:
        if not n.hasDefault:
          error "A constant must have a value", node
        n.inferValType()
        result.constsList.add n
    of nnkProcDef, nnkMethodDef, nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.body.add node.insertSelf(info.name)
    else:
      discard


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
    theClass.insert 1, genConstant(info.name.strVal, c)


proc toInterface*(self: AliasState): IState {.compileTime.} =
  result = (
    getClassMembers:
    (body: NimNode, info: ClassInfo) => self.getClassMembers(body, info),
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


proc getClassMembers(
  self: ImplementationState;
  body: NimNode;
  info: ClassInfo
): ClassMembers {.compileTime.} =
  result.body = newStmtList()
  result.ctorBase = newEmptyNode()
  result.ctorBase2 = newEmptyNode()
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if "noNewDef" in info.pragmas and n.hasDefault:
          error "default values cannot be used with {.noNewDef.}", n
        n.inferValType()
        if n.hasPragma and "ignored" in n[0][1]:
          result.ignoredArgsList.add n
        else:
          result.argsList.add n
    of nnkConstSection:
      for n in node:
        if not n.hasDefault:
          error "A constant must have a value", node
        n.inferValType()
        result.constsList.add n
    of nnkProcDef:
      if node.isConstructor:
        if result.ctorBase.isEmpty:
          result.ctorBase = node.copy()
          result.ctorBase[4] = nnkPragma.newTree(
            newColonExpr(ident"deprecated", newLit"Use Type.new instead")
          )
          result.ctorBase2 = node.copy()
        else:
          error "Constructor already exists", node
      else:
        result.body.add node.insertSelf(info.name)
    of nnkMethodDef, nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.body.add node.insertSelf(info.name)
    else:
      discard


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
  theClass.insert(
    1,
    if members.ctorBase.isEmpty:
      info.defOldNew(members.allArgsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase.assistWithOldDef(
        info,
        members.allArgsList.filter(hasDefault).map rmAsteriskFromIdent
      )
  )
  theClass.insert(
    1,
    if members.ctorBase2.isEmpty:
      info.defNew(members.allArgsList.map rmAsteriskFromIdent)
    else:
      members.ctorBase2.assistWithDef(
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
    theClass.insert 1, genConstant(info.name.strVal, c)
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
    getClassMembers:
    (body: NimNode, info: ClassInfo) => self.getClassMembers(body, info),
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
