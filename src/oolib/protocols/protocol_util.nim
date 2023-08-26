import
  std/macrocache,
  std/macros

type
  ProtocolSignature* = tuple
    protocolName: NimNode
    isPublic: bool
    variables: seq[NimNode]
    procedures: seq[NimNode]

const ProtocolTable* = CacheTable"ProtocolCacheTable"

proc decomposeIdentDefs*(identDefs: NimNode): seq[NimNode] {.compileTime.} =
  for name in identDefs[0..^3]:
    result.add newIdentDefs(
      name = name,
      kind = identDefs[^2],
      default = identDefs[^1]
    )

proc insertSelf*(theProc, name: NimNode) {.compileTime.} =
  insert(theProc.params, 1, newIdentDefs(ident"self", name))

proc markWithAsterisk*(typeNode: NimNode) {.compileTime.} =
  typeNode[0][0] = typeNode[0][0].postfix"*"

proc hasPragma*(identDef: NimNode): bool {.compileTime.} =
  identDef.expectLen(3)
  result = identDef[0].kind == nnkPragmaExpr

proc deletePragmasFromIdent*(identDef: NimNode): NimNode {.compileTime.} =
  identDef.expectLen(3)
  result = block:
    if identDef.hasPragma:
      newIdentDefs(
        name = identDef[0][0],
        kind = identDef[1],
        default = identDef[2]
      )
    else:
      newIdentDefs(
        name = identDef[0],
        kind = identDef[1],
        default = identDef[2]
      )

proc deletePragmasFromProc*(theProc: NimNode): NimNode {.compileTime.} =
  result = theProc.copyNimTree()
  result.pragma = newEmptyNode()
