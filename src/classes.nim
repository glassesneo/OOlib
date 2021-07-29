import macros
import classespkg / [util]


macro class*(name, body: untyped): untyped =
  let status = parseClassName(name)
  block:
    let
      className = status.name
      baseName = status.base
      classDefStmt = block:
        case status.kind
        of Normal:
          if status.isPub:
            quote:
              type `className`* = ref object of RootObj
          else:
            quote:
              type `className` = ref object of RootObj
        of Inheritance:
          if status.isPub:
            quote:
              type `className`* = ref object of `baseName`
          else:
            quote:
              type `className` = ref object of `baseName`
        of Distinct:
          if status.isPub:
            quote:
              type `className`* = distinct `baseName`
          else:
            quote:
              type `className` = distinct `baseName`


    result = newStmtList classDefStmt
