import macros, sequtils
import oolibpkg / [util]


macro class*(head, body: untyped): untyped =
  let
    status = parseHead(head)
  var
    argsList: seq[NimNode]
    cStatus: ConstructorStatus
  result = defClass(status)
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if n[^2].isEmpty:
          error "Please write the variable type. `class` macro does not have type inference. #5", n
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
    of nnkDiscardStmt:
      return
    else:
      error "Unsupported syntax #1", body
  if cStatus.hasConstructor:
    result.insertIn1st cStatus.node.assistWithDef(
      status,
      argsList.filterIt(not it.last.isEmpty).map rmAsteriskFromIdent
    )
  elif status.kind == Inheritance: discard
  else:
    result.insertIn1st status.defNew(argsList.map rmAsteriskFromIdent)
  result[0][0][2][0][2] = argsList.map(delDefaultValue).toRecList()
