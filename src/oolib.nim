import macros, sequtils
import oolibpkg / [sub, util, info, parse]
export optBase, pClass

macro class*(
    head: untyped{nkIdent | nkCommand | nkInfix | nkCall | nkPragmaExpr},
    body: untyped{nkStmtList}
): untyped =
  let
    info = parseHead(head)
  result = defClass(info)

  var
    classBody: NimNode
    argsList, constsList: seq[NimNode]
    cState: ConstructorState
  (classBody, argsList, constsList, cState) = parseBody(body, info)
  result.add classBody.copy()

  if cState.hasConstructor:
    result.insertIn1st cState.node.assistWithDef(
      info,
      argsList.filterIt(not it.last.isEmpty).map rmAsteriskFromIdent
    )
  elif info.kind != Normal: discard
  else:
    result.insertIn1st info.defNew(argsList.map rmAsteriskFromIdent)
  for c in constsList:
    result.insertIn1st genConstant(info.name.strVal, c)
  if info.kind in {Normal, Inheritance}:
    result[0][0][2][0][2] = argsList.map(delDefaultValue).toRecList()


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`
  T.isClass()
