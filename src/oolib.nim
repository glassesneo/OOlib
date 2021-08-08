import macros
import oolibpkg / [util]


macro class*(head, body: untyped): untyped =
  let
    status = parseHead(head)
  var
    recList = newNimNode(nnkRecList)
    argsList, hasDefaultArgsList: seq[NimNode]
    hasConstructor = false
    constructorNode: NimNode
  result = defClass(status)
  for node in body.children:
    case node.kind
    of nnkVarSection:
      for n in node.children:
        if n[^2].isEmpty:
          error "please write the variable type. `class` macro does not have type inference.", n
        argsList.add n
        if not n.last.isEmpty:
          hasDefaultArgsList.add n
        recList.add delValue(n)
    of nnkProcDef:
      if node.isConstructor:
        if hasConstructor: error "constructor already exists.", node
        hasConstructor = true
        constructorNode = node
      else:
        result.add node.insertSelf(status.name)
    of nnkFuncDef, nnkMethodDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.add node.insertSelf(status.name)
    of nnkDiscardStmt:
      return
    else:
      error "cannot parse.", body
  for n in hasDefaultArgsList: echo n.treeRepr
  if hasConstructor:
    result.insertIn1st(
      constructorNode.insertStmts(
        status.name,
        hasDefaultArgsList
      )
    )
  else:
    let theNew = genTheNew(status.isPub):
      name = ident "new"&status.name.strVal
      params = status.name&argsList
      body = genNewBody(
        status.name,
        decomposeNameOfVariables argsList
      )
    result.insert(1, theNew)
  result[0][0][2][0][2] = recList
