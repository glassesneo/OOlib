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
  result = defClass parseClassName(name)
  result[0][0][2][0][2] = defClassBody(body)
