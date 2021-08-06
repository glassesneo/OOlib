{.experimental: "strictFuncs".}
{.experimental: "codeReordering".}
import macros, algorithm
import tmpl


using
  theProc, node: NimNode


type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct

  ClassStatus* = object
    isPub*, isOpen*: bool
    kind*: ClassKind
    name*, base*: NimNode


func newClassStatus(
    isPub,
    isOpen = false;
    kind = Normal;
    name: NimNode;
    base = ident "RootObj"
): ClassStatus =
  ClassStatus(
    isPub: isPub,
    isOpen: isOpen,
    kind: kind,
    name: name,
    base: base
  )


func isDistinct(node): bool =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy


func isPub(node): bool =
  node.kind == nnkCommand and node[0].eqIdent"pub"


func isOpen(node): bool =
  node.kind == nnkPragmaExpr and node[1][0].eqIdent"open"


func isInheritance(node): bool =
  node.kind == nnkInfix and node[0].eqIdent"of"


proc insertNewParams(theProc; vars: seq[NimNode]): NimNode {.discardable.} =
  result = theProc
  for v in vars.reversed:
    result.params.insert(1, v)


func insertNewBody(typeName, body: NimNode; vars: seq[NimNode]): NimNode =
  result = body
  if body[0].kind == nnkDiscardStmt:
    return
  result.insert(0, newSelfStmt(typeName))
  for v in vars:
    result.insert(1, getAst(asgnInNew v))
  result.add newResultAssignment()


func replaceReturnTypeWith(theProc; typeName: NimNode): NimNode {.discardable.} =
  result = theProc
  result.params[0] = typeName


func newPostfix(node): NimNode =
  newNimNode(nnkPostfix).add(ident "*", node)


func determineStatus(node; isPub: bool): ClassStatus =
  case node.kind
  of nnkIdent:
    result = newClassStatus(
      isPub = isPub,
      kind = Normal,
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
    error "not enough arguments in the bracket."
  of nnkInfix:
    if node.isInheritance:
      if node[2].isOpen:
        return newClassStatus(
          isPub = isPub,
          isOpen = true,
          kind = Inheritance,
          name = node[1],
          base = node[2][0]
        )
      return newClassStatus(
        isPub = isPub,
        kind = Inheritance,
        name = node[1],
        base = node[2]
      )
    error "cannot parse.", node
  of nnkPragmaExpr:
    if node.isOpen:
      if node[0].isDistinct:
        return newClassStatus(
          isPub = isPub,
          isOpen = true,
          kind = Distinct,
          name = node[0][0],
          base = node[0][1][0]
        )
      return newClassStatus(
        isPub = isPub,
        isOpen = true,
        name = node[0]
      )
    error "cannot parse."
  else:
    error "cannot parse.", node


func parseHead*(head: NimNode): ClassStatus =
  case head.len
  of 0:
    result = newClassStatus(name = head)
  of 1:
    error "not enough argument.", head
  of 2:
    result =
      if head.isPub:
        determineStatus(head[1], head.isPub)
      else:
        determineStatus(head, head.isPub)
  of 3:
    if head.kind == nnkInfix and head.isInheritance:
      return newClassStatus(
        kind = Inheritance,
        name = head[1],
        base = head[2]
      )
    error "cannot parse.", head
  else:
    error "too many arguments", head


func insertSelf*(node; name: NimNode): NimNode {.discardable.} =
  result = node
  result.params.insert(1, newIdentDefs(ident "self", name))


func isConstructor*(node): bool =
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func delValue*(node): NimNode {.discardable.} =
  result = node
  if node.last.kind != nnkEmpty:
    result[result.len-1] = newEmptyNode()


func decomposeNameOfVariables*(s: seq[NimNode]): seq[NimNode] =
  for def in s:
    for v in def[0..(def.len - 3)]:
      result.add v


func newSelfStmt*(name: NimNode): NimNode =
  newVarStmt(ident "self", newCall name)


func newResultAssignment*: NimNode =
  newAssignment(ident "result", ident "self")


proc genNewBody*(name: NimNode; vars: seq[NimNode]): NimNode =
  result = newStmtList newSelfStmt(name)
  for v in vars:
    result.insert(1, getAst(asgnInNew v))
  result.add newResultAssignment()


proc insertStatementsInNew*(
    typeName,
    constructor: NimNode;
    defs: seq[NimNode]
): NimNode =
  result = constructor
  result.name = ident "new"&typeName.strVal
  result
    .insertNewParams(defs)
    .replaceReturnTypeWith(typeName)
  result.body = insertNewBody(
    typeName,
    constructor.body,
    decomposeNameOfVariables defs
  )


func isAbstract*(node): bool =
  node.kind == nnkMethodDef and node.last.kind == nnkEmpty


func markWithAsterisk*(theProc): NimNode {.discardable.} =
  result = theProc
  result.name = newPostfix(theProc.name)


func defClass*(status: ClassStatus): NimNode =
  var classDef =
    case status.kind
    of Normal, Inheritance:
      if status.isPub:
        getAst defObjPub(status.name, status.base)
      else:
        getAst defObj(status.name, status.base)
    of Distinct:
      if status.isPub:
        getAst defDistinctPub(status.name, status.base)
      else:
        getAst defDistinct(status.name, status.base)

  if status.isOpen:
    classDef[0][0] = classDef[0][0][0]
  result = newStmtList classDef
