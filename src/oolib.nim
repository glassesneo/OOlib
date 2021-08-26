import macros
import oolibpkg / [util]


macro class*(head, body: untyped): untyped =
  let
    status = parseHead(head)
  var
    recList = newNimNode(nnkRecList)
    argsList, argsListWithDefault: seq[NimNode]
    cStatus: ConstructorStatus
  result = defClass(status)
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if n[^2].isEmpty:
          error "Please write the variable type. `class` macro does not have type inference. #5", n
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
  result[0][0][2][0][2] = recList
