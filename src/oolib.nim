import macros, sequtils
import oolibpkg / [sub, util, classutil, parse]
import oolibpkg / state / [states, context]
export optBase, pClass

macro class*(
    head: untyped{nkIdent | nkCommand | nkInfix | nkCall | nkPragmaExpr},
    body: untyped{nkStmtList}
): untyped =
  var
    info = parseHead(head)
    (classBody, argsList, constsList, partOfCtor) = parseBody(body, info)

  result = defClass(info)
  result.add classBody.copy()

  let
    context = newContext(newState(info))
    ctorNode = context.defConstructor(info, partOfCtor, argsList)

  if not ctorNode.isEmpty:
    result.insertIn1st ctorNode
  for c in constsList:
    result.insertIn1st genConstant(info.name.strVal, c)
  if info.kind in {Normal, Inheritance}:
    result[0][0][2][0][2] = argsList.map(delDefaultValue).toRecList()


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`.
  T.isClass()
