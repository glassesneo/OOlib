{.experimental: "strictFuncs".}
import macros, algorithm

using
  node: NimNode

type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct

  ClassStatus* = object
    isPub*: bool
    kind*: ClassKind
    name*, base*: NimNode


func newClassStatus(isPub = false; kind = Normal; name: NimNode;
    base = "RootObj".ident): ClassStatus =
  result = ClassStatus(
    isPub: isPub,
    kind: kind,
    name: name,
    base: base
  )


func isDistinct(node): bool =
  ## node.kind must be nnkCall
  result = node[1].kind == nnkDistinctTy


func isPub(node): bool =
  result =
    node.kind == nnkCommand and node[0].eqIdent"pub"


func isInheritance(node): bool =
  ## node.kind must be nnkInfix
  result = node[0].eqIdent"of"


func determineStatus(node; isPub: bool): ClassStatus =
  case node.kind
  of nnkIdent:
    result = newClassStatus(isPub = isPub, kind = Normal, name = node)
  of nnkCall:
    if node.isDistinct:
      return newClassStatus(isPub = isPub, kind = Distinct, name = node[
          0], base = node[1][0])
    error "not enough arguments in the bracket."
  of nnkInfix:
    if node.isInheritance:
      return newClassStatus(isPub = isPub, kind = Inheritance, name = node[
          1], base = node[2])
    error("cannot parse.", node)
  else:
    error("cannot parse.", node)


func parseClassName*(className: NimNode): ClassStatus =
  case className.len
  of 0:
    result = newClassStatus(name = className)
  of 1:
    error("not enough argument.", className)
  of 2:
    result = if className.isPub:
      determineStatus(className[1], className.isPub)
      else:
        determineStatus(className, className.isPub)
  of 3:
    if className.kind == nnkInfix and className.isInheritance:
      return newClassStatus(kind = Inheritance, name = className[1],
          base = className[2])
    error("cannot parse.", className)
  else:
    error("too many arguments", className)


template defObj*(className, baseName) =
  type className = ref object of baseName

template defObjPub*(className, baseName) =
  type className* = ref object of baseName

template defDistinct*(className, baseName) =
  type className = distinct baseName

template defDistinctPub*(className, baseName) =
  type className* = distinct baseName


func insertSelf*(node; name: NimNode): NimNode =
  result = node
  result.params.insert(1, newIdentDefs(ident"self", name))


func isConstructor*(node): bool =
  result =
    node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func delValue*(node): NimNode =
  result = node
  if node.last.kind != nnkEmpty:
    result[result.len-1] = newEmptyNode()


proc toSeq*(node): seq[NimNode] =
  node.expectKind nnkRecList
  for n in node.children:
    result.add n
    echo n.last.kind


func decomposeNameOfVariables*(s: seq[NimNode]): seq[NimNode] =
  for def in s:
    for v in def[0..(def.len - 3)]:
      result.add v


func toRecList*(s: seq[NimNode]): NimNode =
  result = newNimNode(nnkRecList)
  for n in s:
    result.add n


template asgnInNew*(name) =
  self.name = name


func newSelfStmt*(name: NimNode): NimNode =
  result = newVarStmt(ident "self", newCall name)


func newResultAssignment*: NimNode =
  result = newAssignment(ident "result", ident "self")


proc genNewBody*(name: NimNode; vars: seq[NimNode]): NimNode =
  result = newStmtList newSelfStmt(name)
  for v in vars:
    result.insert(1, getAst(asgnInNew v))
  result.add newResultAssignment()


proc insertNewParams*(params: NimNode; vars: seq[NimNode]): NimNode =
  result = params
  for v in vars.reversed:
    # params[0] must be return type
    result.insert(1, v)


func insertNewBody(typeName, body: NimNode; vars: seq[NimNode]): NimNode =
  result = body
  if body[0].kind == nnkDiscardStmt:
    return
  result.insert(0, newSelfStmt(typeName))
  for v in vars:
    result.insert(1, getAst(asgnInNew v))
  result.add newResultAssignment()


func replaceReturnTypeWith(params: NimNode; typeName: NimNode): NimNode =
  result = params
  result[0] = typeName


proc insertStatementsInNew*(typeName, constructor: NimNode; defs: seq[
    NimNode]): NimNode =
  result = constructor
  result.name = ident("new" & typeName.strVal)
  result.params = insertNewParams(constructor.params,
      defs).replaceReturnTypeWith(typeName)
  result.body = insertNewBody(typeName, constructor.body,
      decomposeNameOfVariables defs)
