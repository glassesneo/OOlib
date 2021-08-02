import macros
import classespkg / [util]


func defClass(status: ClassStatus): NimNode =
  let classDef = block:
    case status.kind
    of Normal:
      if status.isPub:
        getAst defObjPub(status.name, RootObj)
      else:
        getAst defObj(status.name, RootObj)
    of Inheritance:
      if status.isPub:
        getAst defObjPub(status.name, status.base)
      else:
        getAst defObj(status.name, status.base)
    of Distinct:
      if status.isPub:
        getAst defDistinctPub(status.name, status.base)
      else:
        getAst defDistinct(status.name, status.base)
  result = newStmtList classDef


macro class*(head, body: untyped): untyped =
  let
    status = parseClassName(head)
  var
    recList = newNimNode(nnkRecList)
    paramsList, hasDefaultParamsList: seq[NimNode]
    hasConstructor = false
    constructorNode: NimNode
  result = defClass(status)
  for node in body.children:
    case node.kind
    of nnkVarSection:
      for n in node.children:
        if n[n.len-2].kind == nnkEmpty:
          error("please write the variable type. `class` macro does not have type inference.", n)
        paramsList.add n
        if n.last.kind != nnkEmpty:
          hasDefaultParamsList.add n
        recList.add delValue(n)
    of nnkProcDef, nnkFuncDef, nnkMethodDef, nnkIteratorDef, nnkTemplateDef:
      if node.isConstructor:
        if hasConstructor: error("constructor already exists.", node)
        hasConstructor = true
        constructorNode = node
      else:
        result.add node.insertSelf(status.name)
    of nnkDiscardStmt:
      return
    else:
      error("cannot parse.", body)
  for n in hasDefaultParamsList: echo n.treeRepr
  if hasConstructor:
    result.insert(
      1,
      insertStatementsInNew(
        status.name,
        constructorNode,
        hasDefaultParamsList
      )
    )
  else:
    let
      newName = block:
        if status.isPub:
          newNimNode(nnkPostfix).add(
            ident "*",
            ident "new" & status.name.strVal
          )
        else:
          ident "new" & status.name.strVal
      params = status.name & paramsList
      newBody = genNewBody(status.name, decomposeNameOfVariables paramsList)
    result.insert(1, newProc(newName, params, newBody))
  result[0][0][2][0][2] = recList
  echo result.treeRepr
