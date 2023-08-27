import
  std/macros

type
  ClassKind* = enum
    NormalClass
    DistinctClass
    NamedTupleClass
    ImplementClass

  ClassSignature* = tuple
    className: NimNode
    baseName: NimNode
    classKind: ClassKind
    isPublic: bool
    protocols: seq[NimNode]
    pragmas: seq[NimNode]
    variables: seq[NimNode]
    routines: seq[NimNode]
    constructors: seq[NimNode]

const specialPragmas* = @[
  "initial"
]

proc procedures*(
    signature: ClassSignature
): seq[NimNode] {.compileTime.} =
  for p in signature.routines:
    if p.kind == nnkProcDef:
      result.add p

proc isImplement*(node: NimNode): bool {.compileTime.} =
  node.expectKind(nnkCommand)
  node[0].kind == nnkIdent and
  node[1].kind == nnkCommand and
  node[1][0].eqIdent"impl"

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
    let name = theProc[0].basename
    return name.kind == nnkAccQuoted and name.eqIdent"new"
  else:
    return false

proc insertSelf*(theProc, name: NimNode) {.compileTime.} =
  insert(theProc.params, 1, newIdentDefs(ident"self", name))

proc deleteAsteriskFromIdent*(identDef: NimNode): NimNode {.compileTime.} =
  identDef.expectLen(3)
  result = identDef
  case identDef[0].kind
  of nnkPragmaExpr:
    result[0] = identDef[0][0].basename
  of nnkPostfix:
    result[0] = identDef[0][1]
  of nnkIdent:
    result[0] = identDef[0]
  else:
    error "Unsupported syntax", identDef[0]

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

proc hasAnySpecialPragma*(identDef: NimNode): bool {.compileTime.} =
  identDef.expectLen(3)
  identDef[0].expectKind(nnkPragmaExpr)
  for pragma in identDef[0][1]:
    if pragma.strVal in specialPragmas:
      return true

proc deleteSpecialPragmasFromIdent*(identDef: NimNode): NimNode {.compileTime.} =
  identDef.expectLen(3)
  result = block:
    if identDef.hasPragma and identDef.hasAnySpecialPragma:
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

func inferValType*(node: NimNode) {.compileTime.} =
  node.expectKind nnkIdentDefs
  node[^2] = node[^2] or newCall(ident"typeof", node[^1])
