import macros
import oolibpkg / [util]
export optBase

macro class*(head, body: untyped): untyped =
  let
    status = parseHead(head)
  var
    recList = newNimNode(nnkRecList)
    argsList, argsListWithDefault, constsList: seq[NimNode]
    cStatus: ConstructorStatus
  result = defClass(status)
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if n[^2].isEmpty:
          # infer type from default
          n[^2] = newCall(ident"typeof", n[^1])
        argsList.add n
        if not n.last.isEmpty:
          argsListWithDefault.add n
        recList.add n.delDefaultValue()
    of nnkProcDef:
      cStatus.updateStatus(node)
      if not node.isConstructor:
        result.add node.insertSelf(status.name)
    of nnkMethodDef:
      if status.kind == Inheritance:
        node.body = replaceSuper(node.body)
        result.add node.insertSelf(status.name).insertSuperStmt(status.base)
      else:
        result.add node.insertSelf(status.name)
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.add node.insertSelf(status.name)
    of nnkConstSection:
      for n in node:
        if n[^2].isEmpty:
          # infer type from default
          n[^2] = newCall(ident"typeof", n[^1])
        if n.last.isEmpty:
          error "Consts must have a value", body
        constsList.add n
    of nnkDiscardStmt:
      return
    else:
      error "Unsupported syntax #1", body
  if cStatus.hasConstructor:
    result.insertIn1st(
      cStatus.node.insertStmts(
        status.isPub,
        status.name,
        argsListWithDefault.rmAsteriskFromEachDef()
      )
    )
  elif status.kind == Inheritance:
    discard
  else:
    let
      argsListWithAsterisksRemoved = argsList.rmAsteriskFromEachDef()
      theNew = genTheNew(status.isPub):
        name = ident "new"&status.name.strVal
        params = status.name&argsListWithAsterisksRemoved
        body = genNewBody(
          status.name,
          argsListWithAsterisksRemoved
        )
    result.insertIn1st theNew
  for c in constsList:
    result.insertIn1st genConstant(status.name.strVal, c)
  result[0][0][2][0][2] = recList
