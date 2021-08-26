{.experimental: "strictFuncs".}
import macros
import tmpl


type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct

  ClassStatus* = tuple
    isPub, isOpen: bool
    kind: ClassKind
    name, base: NimNode

  ConstructorStatus* = tuple
    hasConstructor: bool
    node: NimNode


using
  node, constructor, theProc, typeName, baseName: NimNode
  status: ClassStatus


func newClassStatus(
    isPub,
    isOpen = false;
    kind = Normal;
    name = ident "";
    base: NimNode = nil
): ClassStatus =
  (
    isPub: isPub,
    isOpen: isOpen,
    kind: kind,
    name: name,
    base: base
  )


func isDistinct(node): bool {.compileTime.} =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy


func isPub(node): bool {.compileTime.} =
  node.kind == nnkCommand and node[0].eqIdent"pub"


func isOpen(node): bool {.compileTime.} =
  node.kind == nnkPragmaExpr and node[1][0].eqIdent"open"


func isInheritance(node): bool {.compileTime.} =
  node.kind == nnkInfix and node[0].eqIdent"of"


func isSuperFunc(node): bool {.compileTime.} =
  node.kind == nnkCall and
  node[0].kind == nnkDotExpr and
  node[0][0].eqIdent"super"


func hasAsterisk(node): bool {.compileTime.} =
  node.len > 0 and
  node.kind == nnkPostfix and
  node[0].eqIdent"*"


func isConstructor*(node): bool {.compileTime.} =
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func isEmpty*(node): bool {.compileTime.} =
  node.kind == nnkEmpty


proc updateStatus*(cStatus: var ConstructorStatus; node) {.compileTime.} =
  if node.isConstructor:
    if cStatus.hasConstructor: error "Constructor already exists. #6", node
    cStatus.hasConstructor = true
    cStatus.node = node


func insertIn1st*(node; inserted: NimNode) {.compileTime.} =
  node.insert 1, inserted


func insertSelf*(node; typeName): NimNode {.discardable, compileTime.} =
  result = node
  result.params.insertIn1st newIdentDefs(ident "self", typeName)


proc replaceSuper*(node): NimNode =
  result = node
  if node.isSuperFunc:
    result = newTree(
      nnkCommand,
      ident "procCall",
      copyNimTree(node)
    )
    return
  for i, n in node:
    result[i] = n.replaceSuper()


func newSuperStmt(baseName): NimNode {.compileTime.} =
  newVarStmt ident"super", newCall(baseName, ident "self")


func insertSuperStmt*(theProc; baseName): NimNode {.discardable, compileTime.} =
  result = theProc
  result.body.insert 0, newSuperStmt(baseName)


func delDefaultValue*(node): NimNode {.discardable, compileTime.} =
  result = node
  result[^1] = newEmptyNode()


func newPostfix(node): NimNode {.compileTime.} =
  newNimNode(nnkPostfix).add ident"*", node


proc decideStatus(node; isPub: bool): ClassStatus {.compileTime.} =
  case node.kind
  of nnkIdent:
    result = newClassStatus(
      isPub = isPub,
      name = node
    )
  of nnkCall:
    if node.isDistinct:
      return newClassStatus(
        isPub = isPub,
        kind = Distinct,
        name = node[0],
        base = node[1][0]
      )
    error "Missing `distinct` keyword. #4", node
  of nnkInfix:
    if node.isInheritance:
      result = newClassStatus(
        isPub = isPub,
        kind = Inheritance,
        name = node[1]
      )
      if node[2].isOpen:
        result.isOpen = true
        result.base = node[2][0]
        return
      result.base = node[2]
      return
    error "Unsupported syntax. #1", node
  of nnkPragmaExpr:
    if node.isOpen:
      result = newClassStatus(
        isPub = isPub,
        isOpen = true,
        name = node[0]
      )
      if node[0].isDistinct:
        result.kind = Distinct
        result.name = node[0][0]
        result.base = node[0][1][0]
        return
      return
    error "Unsupported pragma. #2", node
  else:
    error "Unsupported syntax. #1", node


proc parseHead*(head: NimNode): ClassStatus {.compileTime.} =
  case head.len
  of 0:
    result = newClassStatus(name = head)
  of 1:
    error "Unsupported syntax. #1", head
  of 2:
    result = decideStatus(
      if head.isPub: head[1] else: head,
      head.isPub
    )
  of 3:
    if head.isInheritance:
      return newClassStatus(
        kind = Inheritance,
        name = head[1],
        base = head[2]
      )
    error "Unsupported syntax. #1", head
  else:
    error "Too many arguments. #3", head


func astOfAsgnWith(v: NimNode): NimNode {.discardable, compileTime.} =
  getAst asgnWith(v)


func newSelfStmt(typeName): NimNode {.compileTime.} =
  newVarStmt ident"self", newCall(typeName)


func newResultAsgn: NimNode {.compileTime.} =
  newAssignment ident"result", ident"self"


func insertBody(
    constructor,
    typeName;
    vars: seq[NimNode]
): NimNode {.discardable, compileTime.} =
  result = constructor
  if result.body[0].kind == nnkDiscardStmt:
    return
  result.body.insert 0, newSelfStmt(typeName)
  for v in vars:
    result.body.insertIn1st(astOfAsgnWith v)
  result.body.add newResultAsgn()


func rmAsterisk(node): NimNode {.discardable, compileTime.} =
  result = node
  if node.hasAsterisk:
    result = node[1]


func rmAsteriskFromEachDef*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      result.add newIdentDefs(
        v.rmAsterisk(),
        def[^2],
        def[^1]
      )


func decomposeVariables(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      result.add v


proc genNewBody*(typeName: NimNode; vars: seq[NimNode]): NimNode {.compileTime.} =
  result = newStmtList newSelfStmt(typeName)
  for v in vars.decomposeVariables():
    result.insertIn1st astOfAsgnWith(v)
  result.add newResultAsgn()


proc insertArgs(
    constructor;
    vars: seq[NimNode]
): NimNode {.discardable, compileTime.} =
  result = constructor
  for v in vars[0..^1]:
    result.params.insertIn1st(v)


func replaceReturnTypeWith(
    constructor,
    typeName
): NimNode {.discardable, compileTime.} =
  result = constructor
  result.params[0] = typeName


proc insertStmts*(
    node;
    isPub: bool;
    typeName;
    args: seq[NimNode]
): NimNode {.discardable, compileTime.} =
  result = node
  result.name =
    if isPub:
      newPostfix (ident "new"&typeName.strVal)
    else:
      ident "new"&typeName.strVal
  result
    .insertArgs(args)
    .replaceReturnTypeWith(typeName)
    .insertBody(
      typeName,
      args.decomposeVariables()
    )


func markWithAsterisk*(theProc): NimNode {.discardable, compileTime.} =
  # Because it's used in template, must be exported.
  result = theProc
  result.name = newPostfix(theProc.name)


func defObj(status): NimNode {.compileTime.} =
  result = getAst defObj(status.name)
  if status.isPub:
    result[0][0] = newPostfix(result[0][0])
  if status.isOpen:
    result[0][2][0][1] = newNimNode(nnkOfInherit).add ident "RootObj"


func defObjWithBase(status): NimNode {.compileTime.} =
  result = getAst defObjWithBase(status.name, status.base)
  if status.isPub:
    result[0][0] = newPostfix(result[0][0])


func defDistinct(status): NimNode {.compileTime.} =
  result = getAst defDistinct(status.name, status.base)
  if status.isPub:
    result[0][0][0] = newPostfix(result[0][0][0])
  if status.isOpen:
    result[0][0][1][0] = ident "inheritable"


func getAstOfClassDef(status: ClassStatus): NimNode {.compileTime.} =
  result =
    case status.kind
    of Normal:
      status.defObj()
    of Inheritance:
      status.defObjWithBase()
    of Distinct:
      status.defDistinct()


func defClass*(status: ClassStatus): NimNode {.compileTime.} =
  newStmtList getAstOfClassDef(status)


template genTheNew*(isPub: bool; b: untyped): NimNode =
  block:
    var
      name {.inject.}: NimNode
      params {.inject.}: seq[NimNode]
      body {.inject.}: NimNode
    b
    if isPub:
      newProc(name, params, body).markWithAsterisk()
    else:
      newProc(name, params, body)
