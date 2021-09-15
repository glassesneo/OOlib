import macros, sequtils
import oolibpkg / [sub, util]
export optBase, pClass

macro class*(head: untyped{~nkStmtList}, body: untyped{nkStmtList}): untyped =
  let
    status = parseHead(head)
  var
    argsList, constsList: seq[NimNode]
    cStatus: ConstructorStatus
  result = defClass(status)
  for node in body:
    case node.kind
    of nnkVarSection:
      if status.kind == Alias:
        error "An alias class cannot have variables", node
      for n in node:
        n[^2] = n[^2] or newCall(ident"typeof", n[^1])
        argsList.add n
    of nnkProcDef:
      cStatus.updateStatus(node)
      if node.isConstructor: continue
      result.add node.insertSelf(status.name)
    of nnkMethodDef:
      if status.kind == Inheritance:
        node.body = replaceSuper(node.body)
        result.add node.insertSelf(status.name).insertSuperStmt(status.base)
        continue
      result.add node.insertSelf(status.name)
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      result.add node.insertSelf(status.name)
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
  if cStatus.hasConstructor:
    result.insertIn1st cStatus.node.assistWithDef(
      status,
      argsList.filterIt(not it.last.isEmpty).map rmAsteriskFromIdent
    )
  elif status.kind in [Inheritance, Alias]: discard
  else:
    result.insertIn1st status.defNew(argsList.map rmAsteriskFromIdent)
  for c in constsList:
    result.insertIn1st genConstant(status.name.strVal, c)
  result[0][0][2][0][2] = argsList.map(delDefaultValue).toRecList()


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`
  T.isClass()
