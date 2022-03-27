{.experimental: "strictFuncs".}
import
  std/macros


using
  node, constructor, theProc, typeName, baseName: NimNode
  isPub: bool


func contains*(node; str: string): bool {.compileTime.} =
  for n in node:
    if n.eqIdent str:
      return true


func isPub*(node): bool {.compileTime.} =
  node.kind == nnkCommand and node[0].eqIdent"pub"


func isEmpty*(node): bool {.compileTime.} =
  node.kind == nnkEmpty


func hasDefault*(node): bool {.compileTime.} =
  ## `node` has to be `nnkIdentDefs` or `nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  not node.last.isEmpty


func insertIn1st*(node; inserted: NimNode) {.compileTime.} =
  node.insert 1, inserted


func insertSelf*(theProc; typeName): NimNode {.compileTime.} =
  ## Inserts `self: typeName` in the 1st of theProc.params.
  result = theProc
  result.params.insertIn1st newIdentDefs(ident "self", typeName)


template markWithPostfix*(node) =
  node = nnkPostfix.newTree(ident"*", node)


func decomposeDefsIntoVars*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      if v.kind == nnkPragmaExpr:
        result.add v[0]
        continue
      result.add v


template newPragmaExpr*(node; pragma: string) =
  node = nnkPragmaExpr.newTree(
    node,
    nnkPragma.newTree(ident pragma)
  )
