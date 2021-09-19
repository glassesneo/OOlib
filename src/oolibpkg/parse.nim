import macros
import util, classutil


using
  node: NimNode
  argsList, constsList: var seq[NimNode]
  info: ClassInfo
  cState: var ConstructorState


proc parseVar(node; argsList; info) {.compileTime.} =
  if info.kind == Alias:
    error "An alias class cannot have variables", node
  for n in node:
    n[^2] = n[^2] or newCall(ident"typeof", n[^1])
    argsList.add n


proc parseConst(node; constsList) {.compileTime.} =
  for n in node:
    n[^2] = n[^2] or newCall(ident"typeof", n[^1])
    if n.last.isEmpty:
      error "A constant must have a value", node
    constsList.add n


proc parseCallable(node, info, cState): NimNode {.compileTime.} =
  result = nnkStmtList.newNimNode()
  case node.kind
  of nnkProcDef:
    cState.updateStatus(node)
    if node.isConstructor: return
    result.add node.insertSelf(info.name)
  of nnkMethodDef:
    if info.kind == Inheritance:
      node.body = replaceSuper(node.body)
      result.add node.insertSelf(info.name).insertSuperStmt(info.base)
      return
    result.add node.insertSelf(info.name)
  of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
    result.add node.insertSelf(info.name)
  else: discard



proc parseBody*(
    body: NimNode;
    info;
): (NimNode, seq[NimNode], seq[NimNode], ConstructorState) {.compileTime.} =
  var
    argsList, constsList: seq[NimNode]
    cState: ConstructorState
    classBody = nnkStmtList.newNimNode()
  for node in body:
    case node.kind
    of nnkVarSection:
      parseVar(node, argsList, info)
    of nnkConstSection:
      parseConst(node, constsList)
    of nnkDiscardStmt:
      discard
    elif node.kind in (RoutineNodes - {nnkDo, nnkLambda, nnkMacroDef}):
      parseCallable(node, info, cState).copyChildrenTo classBody
    else: discard
  result = (classBody, argsList, constsList, cState)
