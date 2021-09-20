import macros
import util, tmpl

type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct
    Alias

  ClassInfo* = tuple
    isPub, isOpen: bool
    kind: ClassKind
    name, base, node: NimNode

using
  node, constructor: NimNode
  info: ClassInfo
  isPub: bool


func newClassInfo(
    isPub,
    isOpen = false;
    kind = Normal;
    name: NimNode;
    base: NimNode = nil
): ClassInfo =
  (
    isPub: isPub,
    isOpen: isOpen,
    kind: kind,
    name: name,
    base: base,
    node: newEmptyNode()
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
      if node[2].isOpen:
        return newClassInfo(
          isPub = isPub,
          isOpen = true,
          kind = Inheritance,
          name = node[1],
          base = node[2][0]
        )
      return newClassInfo(
        isPub = isPub,
        isOpen = true,
        kind = Inheritance,
        name = node[1],
        base = node[2]
      )
    error "Unsupported syntax", node
  of nnkPragmaExpr:
    if node.isOpen:
      result = newClassInfo(
        isPub = isPub,
        isOpen = true,
        name = node[0]
      )
      if node[0].isDistinct:
        return newClassInfo(
          isPub = isPub,
          isOpen = true,
          kind = Distinct,
          name = node[0][0],
          base = node[0][1][0]
        )
      return
    error "Unsupported pragma", node
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
      if head[2].isOpen:
        warning "{.open.} is ignored in a definition of subclass", head
        return newClassInfo(
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


func defObj*(info): NimNode {.compileTime.} =
  result = getAst defObj(info.name)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  if info.isOpen:
    result[0][2][0][1] = nnkOfInherit.newTree ident"RootObj"
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


func defObjWithBase*(info): NimNode {.compileTime.} =
  result = getAst defObjWithBase(info.name, info.base)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


func defDistinct*(info): NimNode {.compileTime.} =
  result = getAst defDistinct(info.name, info.base)
  if info.isPub:
    result[0][0][0] = newPostfix(result[0][0][0])
  if info.isOpen:
    # replace {.final.} with {.inheritable.}
    result[0][0][1][0] = ident "inheritable"
    result[0][0][1].add ident "pClass"


func defAlias*(info): NimNode {.compileTime.} =
  result = getAst defAlias(info.name, info.base)
  if info.isPub:
    result[0][0] = newPostfix(result[0][0])
  result[0][0] = newPragmaExpr(result[0][0], "pClass")


func getAstOfClassDef(info: ClassInfo): NimNode {.compileTime.} =
  result =
    case info.kind
    of Normal:
      info.defObj()
    of Inheritance:
      info.defObjWithBase()
    of Distinct:
      info.defDistinct()
    of Alias:
      info.defAlias()


func defClass*(info: ClassInfo): NimNode {.compileTime.} =
  newStmtList getAstOfClassDef(info)


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
