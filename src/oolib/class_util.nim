import
  std/macros

type
  ClassKind* = enum
    NormalClass
    DistinctClass
    NamedTupleClass

  ClassSignature* = tuple
    className: NimNode
    baseName: NimNode
    classKind: ClassKind
    isPublic: bool
    pragmas: seq[NimNode]
    variables: seq[NimNode]
    routines: seq[NimNode]
    constructors: seq[NimNode]

proc decomposeIdentDefs*(identDefs: NimNode): seq[NimNode] {.compileTime.} =
  for name in identDefs[0..^3]:
    result.add newIdentDefs(
      name = name,
      kind = identDefs[^2],
      default = identDefs[^1]
    )

proc isConstructor*(theProc: NimNode): bool {.compileTime.} =
  case theProc[0].kind
  of nnkAccQuoted:
    return theProc.name.eqIdent"new"
  of nnkPostfix:
    let name = unpackPostfix(theProc[0]).node
    return name.kind == nnkAccQuoted and name.eqIdent"new"
  else:
    return false

proc insertSelf*(theProc, name: NimNode) {.compileTime.} =
  insert(theProc.params, 1, newIdentDefs(ident"self", name))

proc markWithAsterisk*(typeNode: NimNode) {.compileTime.} =
  typeNode[0][0] = typeNode[0][0].postfix"*"

proc addPragmas*(
    typeNode: NimNode,
    pragmas: seq[NimNode]
) {.compileTime.} =
  let pragmaNode = nnkPragma.newNimNode()
  for p in pragmas:
    pragmaNode.add(p)

  typeNode[0][0] = nnkPragmaExpr.newTree(
    typeNode[0][0],
    pragmaNode
  )
