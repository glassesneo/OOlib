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


macro class*(name, body: untyped): untyped =
  let
    status = parseClassName(name)
    recList = newNimNode(nnkRecList)
  result = defClass(status)
  for node in body.children:
    case node.kind
    of nnkVarSection:
      for n in node: recList.add n
    of nnkProcDef, nnkFuncDef, nnkMethodDef, nnkIteratorDef, nnkTemplateDef:
      result.add node.insertSelf(status.name)
    of nnkDiscardStmt:
      return
    else:
      error("cannot parse.", body)
  result[0][0][2][0][2] = recList
