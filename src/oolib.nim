import macros, sequtils
import oolibpkg / [util]
export optBase

macro class*(head, body: untyped): untyped =
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
        error "Type Alias cannot have member variables", node
      for n in node:
        if n[^2].isEmpty:
          # infer type from default
          n[^2] = newCall(ident"typeof", n[^1])
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
        if n[^2].isEmpty:
          # infer type from default
          n[^2] = newCall(ident"typeof", n[^1])
        if n.last.isEmpty:
          error "Consts must have a value", body
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


template pClass* {.pragma.}
  ## Be used as pragma.


proc isClass*(T: typedesc): bool =
  ## Whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## An alias for `isClass(T)`
  T.isClass()
