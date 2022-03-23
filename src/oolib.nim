import macros, sequtils
import oolib / [sub, util, classes, protocols]
import oolib / state / [states, context]
export optBase, pClass, pProtocol, ignored

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
  if info.kind in {ClassKind.Normal, ClassKind.Inheritance,
      ClassKind.Implementation}:
    result[0][0][2][0][2] = members.allArgsList.withoutDefault().toRecList()
  if info.kind == Implementation:
    result.add newProc(
      ident"toInterface",
      [info.base],
      newStmtList(
        nnkReturnStmt.newNimNode.add(
          nnkTupleConstr.newNimNode.add(
            members.argsList.decomposeDefsIntoVars().map newVarsColonExpr
      ).add(
          members.body.filterIt(
            it.kind in {nnkProcDef, nnkFuncDef, nnkMethodDef, nnkIteratorDef}
        ).filterIt("ignored" notin it[4]).map newLambdaColonExpr
      )
      )
      )
    ).insertSelf(info.name)


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`.
  T.isClass()


macro protocol*(head: untyped, body: untyped): untyped =
  let
    info = parseProtocolHead(head)
    members = parseProtocolBody(body)
  result = defProtocol(info, members)


proc isProtocol*(T: typedesc): bool =
  ## Returns whether `T` is protocol or not.
  T.hasCustomPragma(pProtocol)


proc isProtocol*[T](instance: T): bool =
  ## Is an alias for `isProtocol(T)`.
  T.isProtocol()
