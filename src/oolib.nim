import macros
import oolib / [sub, util, classutil]
import oolib / state / [states, context]
export optBase, pClass

macro class*(
    head: untyped{nkIdent | nkCommand | nkInfix | nkCall | nkPragmaExpr},
    body: untyped{nkStmtList}
): untyped =
  let
    info = parseClassHead(head)
    context = newContext(newState(info))
  result = context.defClass(info)
  let
    members = parseClassBody(body, info)
  result.add members.body.copy()
  let ctorNode = context.defConstructor(info, members)
  if not ctorNode.isEmpty:
    result.insertIn1st ctorNode
  for c in members.constsList:
    result.insertIn1st genConstant(info.name.strVal, c)
  if info.kind in {Normal, Inheritance}:
    result[0][0][2][0][2] = members.argsListWithoutDefault().toRecList()


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`.
  T.isClass()
