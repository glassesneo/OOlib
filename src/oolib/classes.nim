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


func newClassInfo(
    isPub = false;
    pragmas: seq[string] = @[];
    kind = Normal;
    name: NimNode;
    base: NimNode = nil
): ClassInfo =
  (
    isPub: isPub,
    pragmas: pragmas,
    kind: kind,
    name: name,
    base: base,
  )


func isDistinct(node): bool {.compileTime.} =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy


func isInheritance(node): bool {.compileTime.} =
  node.kind == nnkInfix and node[0].eqIdent"of"


func isConstructor(node): bool {.compileTime.} =
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func hasPragma(node): bool {.compileTime.} =
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[0].kind == nnkPragmaExpr


func inferValType(node: NimNode) {.compileTime.} =
  ## Infers type from default if a type annotation is empty.
  ## `node` has to be `nnkIdentDefs` or `nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[^2] = node[^2] or newCall(ident"typeof", node[^1])


func newSuperStmt(baseName: NimNode): NimNode {.compileTime.} =
  ## Generates `var super = Base(self)`.
  newVarStmt ident"super", newCall(baseName, ident "self")


func insertSuperStmt(theProc, baseName: NimNode): NimNode {.compileTime.} =
  ## Inserts `var super = Base(self)` in the 1st line of `theProc.body`.
  result = theProc
  result.body.insert 0, newSuperStmt(baseName)


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


proc pickState(node; isPub): ClassInfo {.compileTime.} =
  case node.kind
  of nnkIdent:
    result = newClassInfo(
      isPub = isPub,
      name = node
    )
  of nnkCall:
    if node.isDistinct:
      return newClassInfo(
        isPub = isPub,
        kind = Distinct,
        name = node[0],
        base = node[1][0]
      )
    else:
      return newClassInfo(
        isPub = isPub,
        kind = Alias,
        name = node[0],
        base = node[1]
      )
    error "Unsupported syntax", node
  of nnkInfix:
    if node.isInheritance:
      if node[2].kind == nnkPragmaExpr:
        if "open" in node[2][1]:
          warning "{.open.} is ignored in a definition of alias", node
        return newClassInfo(
          isPub = isPub,
          pragmas = node[2][1].toSeq(),
          kind = Inheritance,
          name = node[1],
          base = node[2][0]
        )
      return newClassInfo(
        isPub = isPub,
        kind = Inheritance,
        name = node[1],
        base = node[2]
      )
    error "Unsupported syntax", node
  of nnkPragmaExpr:
    # it's form `class A {.pragma.}` or `class A(T) {.pragma.}`
    if node[0].isDistinct:
      return newClassInfo(
        isPub = isPub,
        pragmas = node[1].toSeq(),
        kind = Distinct,
        name = node[0][0],
        base = node[0][1][0]
      )
    elif node[0].kind == nnkCall:
      if "open" in node[1]:
        warning "{.open.} is ignored in a definition of alias", node
      return newClassInfo(
        isPub = isPub,
        pragmas = node[1].toSeq(),
        kind = Alias,
        name = node[0][0],
        base = node[0][1]
      )
    return newClassInfo(
      isPub = isPub,
      pragmas = node[1].toSeq(),
      name = node[0]
    )
  of nnkCommand:
    if node[1][0].eqIdent"impl":
      return newClassInfo(
        isPub = isPub,
        kind = Implementation,
        name = node[0],
        base = node[1][1]
      )
    error "Unsupported syntax", node
  else:
    error "Unsupported syntax", node


proc getClassInfo*(head: NimNode): ClassInfo {.compileTime.} =
  case head.len
  of 0:
    result = newClassInfo(name = head)
  of 1:
    error "Unsupported syntax", head
  of 2:
    result = pickState(
      if head.isPub: head[1] else: head,
      head.isPub
    )
  of 3:
    if head.isInheritance:
      if head[2].kind == nnkPragmaExpr:
        if "open" in head[2][1]:
          warning "{.open.} is ignored in a definition of subclass", head
        return newClassInfo(
          pragmas = head[2][1].toSeq(),
          kind = Inheritance,
          name = head[1],
          base = head[2][0]
        )
      return newClassInfo(
        kind = Inheritance,
        name = head[1],
        base = head[2]
      )
    error "Unsupported syntax", head
  else:
    error "Too many arguments", head


proc parseClassBody*(body: NimNode; info): ClassMembers {.compileTime.} =
  result.body = newStmtList()
  result.ctorBase = newEmptyNode()
  result.ctorBase2 = newEmptyNode()
  for node in body:
    case node.kind
    of nnkVarSection:
      case info.kind
      of Distinct:
        error "Distinct type cannot have variables", node
      of Alias:
        error "Type alias cannot have variables", node
      else: discard
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
      if info.kind == Inheritance:
        node.body = replaceSuper(node.body)
        result.body.add node.insertSelf(info.name).insertSuperStmt(info.base)
        continue
      result.body.add node.insertSelf(info.name)
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.body.add node.insertSelf(info.name)
    else:
      discard


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
    result.body.insertIn1st getAst(asgnWith v)
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
    result.insertIn1st getAst(asgnWith v)
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
