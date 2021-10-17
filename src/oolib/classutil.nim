import macros
import util


type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct
    Alias

  ClassInfo* = tuple
    isPub: bool
    pragmas: seq[string]
    kind: ClassKind
    name, base: NimNode

using
  node, constructor: NimNode
  info: ClassInfo
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


proc pickStatus(node; isPub): ClassInfo {.compileTime.} =
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
  else:
    error "Unsupported syntax", node


proc parseHead*(head: NimNode): ClassInfo {.compileTime.} =
  case head.len
  of 0:
    result = newClassInfo(name = head)
  of 1:
    error "Unsupported syntax", head
  of 2:
    result = pickStatus(
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


template defNew*(info; args: seq[NimNode]): NimNode =
  var
    name = ident "new"&strVal(info.name)
    params = info.name&args
    body = genNewBody(
      info.name,
      args.decomposeDefsIntoVars()
    )
  if info.isPub:
    newProc(name, params, body).markWithAsterisk()
  else:
    newProc(name, params, body)
