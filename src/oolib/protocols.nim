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
      isPub = head.isPub,
      name = head[1]
    )
  else:
    error "Unsupported syntax", head


func insertSelf(theProc, typeName: NimNode): NimNode {.compileTime.} =
  ## Inserts `self: typeName` in the 1st of theProc.params.
  result = theProc
  result.params.insert 1, newIdentDefs(ident"self", typeName)


proc parseProtocolBody*(body: NimNode, info: ProtocolInfo): ProtocolMembers =
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        result.argList.add n
    of nnkProcDef, nnkFuncDef:
      if node.body.kind == nnkEmpty:
        result.procs.add node
      else:
        result.implementedProcs.add node.insertSelf(info.name)
    of nnkDiscardStmt:
      discard
    else:
      error "Unsupported syntax", node


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
  for v in members.argList:
    result[0][0][2].add v
  for p in members.procs:
    result[0][0][2].add p.toTupleMemberProc()
  for p in members.implementedProcs:
    result.add p
  if info.isPub:
    result[0][0][0] = nnkPostfix.newTree(ident"*", result[0][0][0])
  result[0][0][0] = nnkPragmaExpr.newTree(
    result[0][0][0],
    nnkPragma.newTree(ident "pProtocol")
  )
