import macros
import classespkg / [util]


func defClass(status: ClassStatus): NimNode =
  let
    className = status.name
    baseName = status.base
    classDef = block:
      case status.kind
      of Normal:
        if status.isPub:
          getAst defObjPub(className, RootObj)
        else:
          getAst defObj(className, RootObj)
      of Inheritance:
        if status.isPub:
          getAst defObjPub(className, baseName)
        else:
          getAst defObj(className, baseName)
      of Distinct:
        if status.isPub:
          getAst defDistinctPub(className, baseName)
        else:
          getAst defDistinct(className, baseName)
  result = newStmtList classDef


macro class*(name, body: untyped): untyped =
  result = defClass parseClassName(name)
