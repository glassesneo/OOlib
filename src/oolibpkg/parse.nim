import macros
import util, classutil


using
  node: NimNode
  argsList, constsList: var seq[NimNode]
  info: var ClassInfo


proc parseVar(node; argsList; info) {.compileTime.} =
  ## Parse and convert `node` to member variables.
  ## `node` has to be `nnkVarSection`.
  case info.kind
  of Distinct:
    error "A distinct type cannot have variables", node
  of Alias:
    error "A type alias cannot have variables", node
  else: discard
  for n in node:
    n.inferValType()
    argsList.add n


proc parseConst(node; constsList) {.compileTime.} =
  ## Parse and convert `node` to class data constants.
  ## `node` has to be `nnkConstSection`.
  for n in node:
    n.inferValType()
    if not n.hasDefault:
      error "A constant must have a value", node
    constsList.add n


proc parseCallable(node, info): NimNode {.compileTime.} =
  ## Parse `node` and add sigunatures to routines.
  ## `node` hax to be one of `RoutineNodes - {nnkDo, nnkLambda, nnkMacroDef}`.
  result = nnkStmtList.newNimNode()
  case node.kind
  of nnkProcDef:
    if node.isConstructor:
      if not info.node.isEmpty:
        error "Constructor already exists", node
      info.node = node
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
): (NimNode, seq[NimNode], seq[NimNode]) {.compileTime.} =
  var
    argsList, constsList: seq[NimNode]
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
      parseCallable(node, info).copyChildrenTo classBody
    else: discard
  result = (classBody, argsList, constsList)
