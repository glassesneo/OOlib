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
