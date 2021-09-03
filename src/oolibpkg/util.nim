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
  isPub: bool


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
  ## Whether struct is `super.f()` or not.
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


func insertSelf*(node; typeName): NimNode {.compileTime.} =
  ## Insert `self: typeName` in the 1st of node.params.
  result = node
  result.params.insertIn1st newIdentDefs(ident "self", typeName)


proc replaceSuper*(node): NimNode =
  ## Replace `super.f()` with `procCall Base(self).f()`.
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
  ## Generate `var super = Base(self)`.
  newVarStmt ident"super", newCall(baseName, ident "self")


func insertSuperStmt*(theProc; baseName): NimNode {.compileTime.} =
  ## Insert `var super = Base(self)` in the 1st line of `theProc.body`.
  result = theProc
  result.body.insert 0, newSuperStmt(baseName)


func delDefaultValue*(node): NimNode {.compileTime.} =
  result = node
  result[^1] = newEmptyNode()


func newPostfix(node): NimNode {.compileTime.} =
  newNimNode(nnkPostfix).add ident"*", node


proc decideStatus(node; isPub): ClassStatus {.compileTime.} =
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
      if head[2].isOpen:
        warning "{.open.} is ignored in a definition of subclass", head
        return newClassStatus(
          kind = Inheritance,
          name = head[1],
          base = head[2][0]
        )
      return newClassStatus(
        kind = Inheritance,
        name = head[1],
        base = head[2]
      )
    error "Unsupported syntax. #1", head
  else:
    error "Too many arguments. #3", head


func astOfAsgnWith(v: NimNode): NimNode {.compileTime.} =
  getAst asgnWith(v)


func newSelfStmt(typeName): NimNode {.compileTime.} =
  ## Generate `var self = typeName()`.
  newVarStmt ident"self", newCall(typeName)


func newResultAsgn: NimNode {.compileTime.} =
  newAssignment ident"result", ident"self"


func toRecList*(s: seq[NimNode]): NimNode {.compileTime.} =
  result = nnkRecList.newNimNode()
  for def in s:
    result.add def


func rmAsterisk(node): NimNode {.compileTime.} =
  result = node
  if node.hasAsterisk:
    result = node[1]


proc rmAsteriskFromIdent*(def: NimNode): NimNode {.compileTime.} =
  result = nnkIdentDefs.newNimNode()
  for v in def[0..^3]:
    result.add v.rmAsterisk
  result.add(def[^2]).add(def[^1])


func decomposeDefsIntoVars*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      result.add v


proc genNewBody(typeName; vars: seq[NimNode]): NimNode {.compileTime.} =
  result = newStmtList newSelfStmt(typeName)
  for v in vars:
    result.insertIn1st astOfAsgnWith(v)
  result.add newResultAsgn()


func replaceReturnTypeWith(
    constructor,
    typeName
): NimNode {.compileTime.} =
  result = constructor
  result.params[0] = typeName


proc insertArgs(
    constructor;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  ## Insert `vars` to constructor args.
  result = constructor
  for v in vars[0..^1]:
    result.params.insertIn1st(v)


proc addSignatures(
    constructor;
    status;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Add signatures to `constructor`.
  result = constructor
  result.name =
    if status.isPub:
      newPostfix (ident "new"&status.name.strVal)
    else:
      ident "new"&status.name.strVal
  return result
    .replaceReturnTypeWith(status.name)
    .insertArgs(args)


func insertBody(
    constructor;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  result = constructor
  if result.body[0].kind == nnkDiscardStmt:
    return
  result.body.insert 0, newSelfStmt(result.params[0])
  for v in vars.decomposeDefsIntoVars():
    result.body.insertIn1st(astOfAsgnWith v)
  result.body.add newResultAsgn()


proc assistWithDef*(
    constructor;
    status;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Add signatures and insert body to `constructor`.
  result = constructor
  return result
    .addSignatures(status, args)
    .insertBody(args)


func markWithAsterisk*(theProc): NimNode {.compileTime.} =
  ## Because it's used in template, must be exported.
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


template defNew*(status; args: seq[NimNode]): NimNode =
  var
    name = ident "new"&status.name.strVal
    params = status.name&args
    body = genNewBody(
      status.name,
      args.decomposeDefsIntoVars()
    )
  if status.isPub:
    newProc(name, params, body).markWithAsterisk()
  else:
    newProc(name, params, body)
