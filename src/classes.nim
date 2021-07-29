import macros
import classespkg / [util]



macro class*(name, body: untyped): untyped =
  let status = parseClassName(name)
  block:
    let
      className = status.name
      baseName = status.base
      classDefStmt = block:
        if status.isPub:
          quote:
            type `className`* = ref object of `baseName`
        else:
          quote:
            type `className` = ref object of `baseName`

    result = newStmtList classDefStmt
