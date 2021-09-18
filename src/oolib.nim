import macros, sequtils
import oolibpkg / [sub, util, info]
export optBase, pClass

macro class*(
    head: untyped{nkIdent | nkCommand | nkInfix | nkCall | nkPragmaExpr},
    body: untyped{nkStmtList}
): untyped =
  let
    info = parseHead(head)
  var
    argsList, constsList: seq[NimNode]
    cState: ConstructorState
  result = defClass(info)
  for node in body:
    case node.kind
    of nnkVarSection:
      if info.kind == Alias:
        error "An alias class cannot have variables", node
      for n in node:
        n[^2] = n[^2] or newCall(ident"typeof", n[^1])
        argsList.add n
    of nnkProcDef:
      cState.updateStatus(node)
      if node.isConstructor: continue
      result.add node.insertSelf(info.name)
    of nnkMethodDef:
      if info.kind == Inheritance:
        node.body = replaceSuper(node.body)
        result.add node.insertSelf(info.name).insertSuperStmt(info.base)
        continue
      result.add node.insertSelf(info.name)
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.add node.insertSelf(info.name)
    of nnkConstSection:
      for n in node:
        n[^2] = n[^2] or newCall(ident"typeof", n[^1])
        if n.last.isEmpty:
          error "A constant must have a value", body
        constsList.add n
    of nnkDiscardStmt:
      return
    else:
      error "Unsupported syntax", body
  if cState.hasConstructor:
    result.insertIn1st cState.node.assistWithDef(
      info,
      argsList.filterIt(not it.last.isEmpty).map rmAsteriskFromIdent
    )
  elif info.kind in [Inheritance, Alias]: discard
  else:
    result.insertIn1st info.defNew(argsList.map rmAsteriskFromIdent)
  for c in constsList:
    result.insertIn1st genConstant(info.name.strVal, c)
  result[0][0][2][0][2] = argsList.map(delDefaultValue).toRecList()


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`
  T.isClass()
