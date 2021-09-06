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
      for n in node:
        if n[^2].isEmpty:
          # infer type from default
          n[^2] = newCall(ident"typeof", n[^1])
        argsList.add n
    of nnkProcDef, nnkMethodDef, nnkFuncDef,
      nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      if node.kind == nnkProcDef:
        cStatus.updateStatus(node)
        if node.isConstructor: continue
      elif node.kind == nnkMethodDef and status.kind == Inheritance:
        node.body = replaceSuper(node.body)
        result.add node.insertSelf(status.name).insertSuperStmt(status.base)
        continue
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
  elif status.kind == Inheritance: discard
  else:
    result.insertIn1st status.defNew(argsList.map rmAsteriskFromIdent)
  for c in constsList:
    result.insertIn1st genConstant(status.name.strVal, c)
  result[0][0][2][0][2] = argsList.map(delDefaultValue).toRecList()


template pClass* {.pragma.}
  ## Be used as pragma.


proc isClass*[T](instance: T): bool =
  ## Whether `instance` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*(T: typedesc): bool =
  ## Whether `T` is class or not.
  T.hasCustomPragma(pClass)
