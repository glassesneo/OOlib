import macros
import util, classutil


using
  node: NimNode
  argsList, constsList: var seq[NimNode]
  info: ClassInfo


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


proc parseBody*(
    body: NimNode;
    info;
): (NimNode, seq[NimNode], seq[NimNode], NimNode) {.compileTime.} =
  var
    argsList, constsList: seq[NimNode]
    classBody = nnkStmtList.newNimNode()
    partOfCtor = newEmptyNode()
  for node in body:
    case node.kind
    of nnkVarSection:
      parseVar(node, argsList, info)
    of nnkConstSection:
      parseConst(node, constsList)
    of nnkProcDef:
      if node.isConstructor:
        if partOfCtor.isEmpty:
          partOfCtor = node
        else:
          error "Constructor already exists", node
      else:
        classBody.add node.insertSelf(info.name)
    of nnkMethodDef:
      if info.kind == Inheritance:
        node.body = replaceSuper(node.body)
        classBody.add node.insertSelf(info.name).insertSuperStmt(info.base)
        continue
      classBody.add node.insertSelf(info.name)
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      classBody.add node.insertSelf(info.name)
    of nnkDiscardStmt:
      discard
    else:
      discard
  result = (classBody, argsList, constsList, partOfCtor)
