import
  std/macros,
  util,
  tmpl,
  types


proc newProtocolInfo(
    isPub = false,
    kind = ProtocolKind.Normal,
    name: NimNode
): ProtocolInfo =
  (
    isPub: isPub,
    kind: kind,
    name: name
  )


proc parseProtocolHead*(head: NimNode): ProtocolInfo =
  case head.len:
  of 0:
    result = newProtocolInfo(name = head)
  of 1:
    error "Unsupported syntax", head
  of 2:
    result = newProtocolInfo(
      isPub = head[0].isPub,
      name = head[1]
    )
  else:
    error "Unsupported syntax", head


proc parseProtocolBody*(body: NimNode): ProtocolMembers =
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        result.argsList.add n
    of nnkProcDef, nnkFuncDef:
      result.procs.add node
    #of nnkFuncDef:
    #  result.funcs.add node
    of nnkDiscardStmt:
      discard
    else:
      discard


func toTupleMemberProc(node: NimNode): NimNode =
  if node.kind == nnkFuncDef:
    if node[4].kind == nnkEmpty:
      node[4] = nnkPragma.newTree(
        ident"noSideEffect"
      )
    else:
      node[4].add ident"noSideEffect"

  newIdentDefs node.name, nnkProcTy.newTree(
    node.params,
    node[4]
  )


proc defProtocol*(info: ProtocolInfo, members: ProtocolMembers): NimNode =
  result = newStmtList getAst defProtocol(info.name)
  for v in members.argsList:
    result[0][0][2].add v
  for p in members.procs:
    result[0][0][2].add p.toTupleMemberProc()
  if info.isPub:
    result[0][0][0] = nnkPostfix.newTree(ident"*", result[0][0][0])
  result[0][0][0] = nnkPragmaExpr.newTree(
   result[0][0][0],
    nnkPragma.newTree(ident "pProtocol")
  )
