{.experimental: "strictFuncs".}
{.experimental: "codeReordering".}
import macros
import tmpl


using
  node, constructor, theProc, typeName: NimNode


type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct

  ClassStatus* = tuple
    isPub, isOpen: bool
    kind: ClassKind
    name, base: NimNode


func newClassStatus(
    isPub,
    isOpen = false;
    kind = Normal;
    name = ident "";
    base = ident "RootObj"
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


func isAbstract*(node): bool {.compileTime.} =
  node.kind == nnkMethodDef and node.last.kind == nnkEmpty


func isConstructor*(node): bool {.compileTime.} =
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func isEmpty*(node): bool {.compileTime.} =
  node.kind == nnkEmpty


func newPostfix(node): NimNode {.compileTime.} =
  newNimNode(nnkPostfix).add(ident "*", node)


proc determineStatus(node; isPub: bool): ClassStatus {.compileTime.} =
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
      )
      if node[0].isDistinct:
        result.kind = Distinct
        result.name = node[0][0]
        result.base = node[0][1][0]
        return
      result.name = node[0]
      return
    error "Unsupported pragma. #2", node
  else:
    error "Unsupported syntax. #1", node


func insertIn1st*(node; inserted: NimNode) {.compileTime.} =
  node.insert(1, inserted)


func insertSelf*(node; typeName): NimNode {.discardable, compileTime.} =
  result = node
  result.params.insertIn1st(newIdentDefs(ident "self", typeName))


proc insertArgs(
    constructor;
    vars: seq[NimNode]
): NimNode {.discardable, compileTime.} =
  result = constructor
  for v in vars[0..^1]:
    result.params.insertIn1st(v)


func insertBody(
    constructor,
    typeName;
    vars: seq[NimNode]
): NimNode {.discardable, compileTime.} =
  result = constructor
  if result.body[0].kind == nnkDiscardStmt:
    return
  result.body.insert(0, newSelfStmt(typeName))
  for v in vars:
    result.body.insertIn1st(astOfAsgnWith v)
  result.body.add newResultAsgn()


func replaceReturnTypeWith(
    constructor,
    typeName
): NimNode {.discardable, compileTime.} =
  result = constructor
  result.params[0] = typeName


func astOfAsgnWith(v: NimNode): NimNode {.discardable, compileTime.} =
  getAst asgnWith(v)


func newSelfStmt(typeName): NimNode {.compileTime.} =
  newVarStmt(ident "self", newCall typeName)


func newResultAsgn: NimNode {.compileTime.} =
  newAssignment(ident "result", ident "self")


proc parseHead*(head: NimNode): ClassStatus {.compileTime.} =
  case head.len
  of 0:
    result = newClassStatus(name = head)
  of 1:
    error "Unsupported syntax. #1", head
  of 2:
    result =
      if head.isPub:
        determineStatus(head[1], head.isPub)
      else:
        determineStatus(head, head.isPub)
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


func delValue*(node): NimNode {.discardable, compileTime.} =
  result = node
  if node.last.kind != nnkEmpty:
    result[^1] = newEmptyNode()


func decomposeNameOfVariables*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..(def.len - 3)]:
      result.add v


proc genNewBody*(typeName: NimNode; vars: seq[NimNode]): NimNode {.compileTime.} =
  result = newStmtList newSelfStmt(typeName)
  for v in vars:
    result.insertIn1st(astOfAsgnWith v)
  result.add newResultAsgn()


proc insertStmts*(
    constructor,
    typeName;
    args: seq[NimNode]
): NimNode {.discardable, compileTime.} =
  result = constructor
  result.name = ident "new"&typeName.strVal
  result
    .insertArgs(args)
    .replaceReturnTypeWith(typeName)
    .insertBody(
      typeName,
      decomposeNameOfVariables args
    )


func markWithAsterisk*(theProc): NimNode {.discardable, compileTime.} =
  result = theProc
  result.name = newPostfix(theProc.name)


func getAstOfClassDef(status: ClassStatus): NimNode =
  result =
    case status.kind
    of Normal, Inheritance:
      getAst defObj(status.name, status.base)
    of Distinct:
      getAst defDistinct(status.name, status.base)
  if status.isPub:
    result[0][0][0] = newPostfix(result[0][0][0])
  if status.isOpen:
    result[0][0] = result[0][0][0]


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
