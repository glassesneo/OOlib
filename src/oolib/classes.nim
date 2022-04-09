import
  std/macros,
  std/sequtils,
  util,
  tmpl


type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct
    Alias
    Implementation

  ClassInfo* = tuple
    isPub: bool
    pragmas: seq[string]
    kind: ClassKind
    name, base: NimNode

  ClassMembers* = tuple
    body, ctorBase, ctorBase2: NimNode
    argsList, ignoredArgsList, constsList: seq[NimNode]


using
  node, constructor: NimNode
  info: ClassInfo
  members: ClassMembers
  isPub: bool


func isDistinct(node): bool {.compileTime.} =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy


func isInheritance(node): bool {.compileTime.} =
  node.kind == nnkInfix and node[0].eqIdent"of"


func delDefaultValue(node): NimNode {.compileTime.} =
  result = node
  result[^1] = newEmptyNode()


func toSeq(node: NimNode): seq[string] {.compileTime.} =
  node.expectKind nnkPragma
  for s in node:
    result.add s.strVal


func rmSelf(theProc: NimNode): NimNode {.compileTime.} =
  ## Removes `self: typeName` from the 1st of theProc.params.
  result = theProc.copy
  result.params.del(1, 1)


func newVarsColonExpr*(v: NimNode): NimNode {.compileTime.} =
  newColonExpr(v, newDotExpr(ident"self", v))


func newLambdaColonExpr*(theProc: NimNode): NimNode {.compileTime.} =
  ## Generates `name: proc() = self.name()`.
  var lambdaProc = theProc.rmSelf()
  let name = lambdaProc[0]
  lambdaProc[0] = newEmptyNode()
  lambdaProc.body = newDotExpr(ident"self", name).newCall(
    lambdaProc.params[1..^1].mapIt(it[0])
  )
  result = newColonExpr(name, lambdaProc)


func isSuperFunc*(node): bool {.compileTime.} =
  ## Returns whether struct is `super.f()` or not.
  node.kind == nnkCall and
  node[0].kind == nnkDotExpr and
  node[0][0].eqIdent"super"


proc replaceSuper*(node): NimNode =
  ## Replaces `super.f()` with `procCall Base(self).f()`.
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


func newResultAsgn(rhs: string): NimNode {.compileTime.} =
  newAssignment ident"result", ident rhs


func inheritanceClassInfo(
    result: var ClassInfo;
    node: NimNode
) {.compileTime.} =
  if not node.isInheritance: error "Unsupported syntax", node
  result.kind = Inheritance
  if node[2].kind != nnkPragmaExpr:
    # class A of B
    result.name = node[1]
    result.base = node[2]
    return
  # class A of B {.pragma.}
  if "open" in node[2][1]:
    warning "{.open.} is ignored in a definition of alias", node
  result.pragmas = node[2][1].toSeq()
  result.name = node[1]
  result.base = node[2][0]


proc getClassInfo*(head: NimNode): ClassInfo {.compileTime.} =
  case head.len
  of 0:
    # class A
    result.kind = Normal
    result.name = head
  of 1:
    error "Unsupported syntax", head
  of 2:
    result.isPub = head.isPub
    var node =
      if head.isPub: head[1]
      else: head
    case node.kind
    of nnkIdent:
      # class A
      result.kind = Normal
      result.name = node
    of nnkCall:
      result.name = node[0]
      if node.isDistinct:
        # class A(distinct B)
        result.kind = Distinct
        result.base = node[1][0]
        return
      # class A(B)
      result.kind = Alias
      result.base = node[1]
    of nnkInfix:
      result.inheritanceClassInfo(node)
    of nnkPragmaExpr:
      result.pragmas = node[1].toSeq()
      if node[0].isDistinct:
        # class A(distinct B) {.pragma.}
        result.kind = Distinct
        result.name = node[0][0]
        result.base = node[0][1][0]
      elif node[0].kind == nnkCall:
        # class A(B) {.pragma.}
        if "open" in node[1]:
          warning "{.open.} is ignored in a definition of alias", node
        result.kind = Alias
        result.name = node[0][0]
        result.base = node[0][1]
        return
      # class A {.pragma.}
      result.name = node[0]
    of nnkCommand:
      if node[1][0].eqIdent"impl":
        result.kind = Implementation
        result.name = node[0]
        if node[1][1].kind == nnkPragmaExpr:
          # class A impl IA {.pragma.}
          result.pragmas = node[1][1][1].toSeq()
          result.base = node[1][1][0]
          return
        # class A impl IA
        result.base = node[1][1]
        return
      error "Unsupported syntax", node
    else:
      error "Unsupported syntax", node
  of 3:
    result.isPub = false
    result.inheritanceClassInfo(head)
  else:
    error "Too many arguments", head


func allArgsList*(members): seq[NimNode] {.compileTime.} =
  members.argsList & members.ignoredArgsList


func withoutDefault*(argsList: seq[NimNode]): seq[NimNode] =
  argsList.map delDefaultValue


func newSelfStmt(typeName: NimNode): NimNode {.compileTime.} =
  ## Generates `var self = typeName()`.
  newVarStmt ident"self", newCall(typeName)


func replaceReturnTypeWith(
    constructor,
    typeName: NimNode
): NimNode {.compileTime.} =
  result = constructor
  result.params[0] = typeName


func insertBody(
    constructor: NimNode;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  result = constructor
  if result.body[0].kind == nnkDiscardStmt:
    return
  result.body.insert 0, newSelfStmt(result.params[0])
  for v in vars.decomposeDefsIntoVars():
    result.body.insert 1, getAst(asgnWith v)
  result.body.add newResultAsgn"self"


proc insertArgs(
    constructor: NimNode;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  ## Inserts `vars` to constructor args.
  result = constructor
  for v in vars[0..^1]:
    result.params.add(v)


proc addOldSignatures(
    constructor;
    info;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Adds signatures to `constructor`.
  constructor.name = ident "new"&info.name.strVal
  if info.isPub:
    markWithPostfix(constructor.name)
  return constructor
    .replaceReturnTypeWith(info.name)
    .insertArgs(args)


proc addSignatures(
    constructor;
    info;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Adds signatures to `constructor`.
  constructor.name = ident"new"
  if info.isPub:
    markWithPostfix(constructor.name)
  result = constructor
    .replaceReturnTypeWith(info.name)
    .insertArgs(args)
  result.params.insert 1, newIdentDefs(
    ident"_",
    nnkBracketExpr.newTree(ident"typedesc", info.name)
  )


proc assistWithOldDef*(
    constructor;
    info;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Adds signatures and insert body to `constructor`.
  constructor
    .addOldSignatures(info, args)
    .insertBody(args)


proc assistWithDef*(
    constructor;
    info;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Adds signatures and insert body to `constructor`.
  constructor
    .addSignatures(info, args)
    .insertBody(args)


proc genNewBody(
    typeName: NimNode;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  result = newStmtList newSelfStmt(typeName)
  for v in vars:
    result.insert 1, getAst(asgnWith v)
  result.add newResultAsgn"self"


proc defOldNew*(info; args: seq[NimNode]): NimNode =
  var
    name = ident "new"&strVal(info.name)
    params = info.name&args
    body = genNewBody(
      info.name,
      args.decomposeDefsIntoVars()
    )
  result = newProc(name, params, body)
  if info.isPub:
    markWithPostfix(result.name)
  result[4] = nnkPragma.newTree(
    newColonExpr(ident"deprecated", newLit"Use Type.new instead")
  )


proc defNew*(info; args: seq[NimNode]): NimNode =
  var
    name = ident"new"
    params = info.name&(
      newIdentDefs(
        ident"_",
        nnkBracketExpr.newTree(ident"typedesc", info.name)
      )&args
    )
    body = genNewBody(
      info.name,
      args.decomposeDefsIntoVars()
    )
  result = newProc(name, params, body)
  if info.isPub:
    markWithPostfix(result.name)
