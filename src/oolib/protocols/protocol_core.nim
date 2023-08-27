import
  std/macros,
  std/sequtils,
  ./protocol_util

proc readBody(
    signature: var ProtocolSignature,
    body: NimNode
) {.compileTime.} =
  if body.kind == nnkEmpty:
    return

  for node in body:
    case node.kind
    of nnkVarSection:
      for identDefs in node:
        signature.variables.add decomposeIdentDefs(identDefs)

    of nnkProcDef:
      let theProc = node.copyNimTree

      if theProc.body.kind notin {nnkEmpty, nnkDiscardStmt}:
        error "Protocol cannot have procedure implementation", theProc

      signature.procedures.add theProc

    else:
      error "Unsupported syntax", node

template protocol(protocolName) =
  type protocolName = tuple

proc addVariables(
    typeNode: NimNode,
    variables: seq[NimNode]
) {.compileTime.} =
  for v in variables:
    typeNode[0][2].add v

proc convertIntoIdentDef*(
    theProc: NimNode
): NimNode {.compileTime.} =
  result = newIdentDefs(
    name = theProc[0],
    kind = nnkProcTy.newTree(theProc.params, newEmptyNode())
  )

proc addProcedures(
    typeNode: NimNode,
    procedures: seq[NimNode]
) {.compileTime.} =
  for p in procedures:
    typeNode[0][2].add convertIntoIdentDef(p)

proc defineType(signature: ProtocolSignature): NimNode {.compileTime.} =
  result = newStmtList()
  let typeSection = getAst protocol(signature.protocolName)

  if signature.isPublic:
    markWithAsterisk(typeSection)

  typeSection.addVariables(signature.variables.map(deletePragmasFromIdent))
  typeSection.addProcedures(signature.procedures.map(deletePragmasFromProc))

  result.add typeSection

proc defineProtocol*(
    signature: var ProtocolSignature,
    body: NimNode
): NimNode {.compileTime.} =
  signature.readBody(body)
  result = defineType(signature)
