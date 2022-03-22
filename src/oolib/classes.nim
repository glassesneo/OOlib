import macros, sequtils
import util


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
    body, ctorBase: NimNode
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


proc parseClassHead*(head: NimNode): ClassInfo {.compileTime.} =
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
          result.ctorBase = node
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


proc addSignatures(
    constructor;
    info;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Adds signatures to `constructor`.
  constructor.name =
    if info.isPub:
      newPostfix(ident "new"&info.name.strVal)
    else:
      ident "new"&info.name.strVal
  return constructor
    .replaceReturnTypeWith(info.name)
    .insertArgs(args)


proc assistWithDef*(
    constructor;
    info;
    args: seq[NimNode]
): NimNode {.compileTime.} =
  ## Adds signatures and insert body to `constructor`.
  constructor
    .addSignatures(info, args)
    .insertBody(args)


proc defNew*(info; args: seq[NimNode]): NimNode =
  var
    name = ident "new"&strVal(info.name)
    params = info.name&args
    body = genNewBody(
      info.name,
      args.decomposeDefsIntoVars()
    )
  result =
    if info.isPub:
      newProc(name, params, body).markWithAsterisk()
    else:
      newProc(name, params, body)
