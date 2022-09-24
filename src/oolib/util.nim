{.experimental: "strictFuncs".}
import
  std/macros

func contains*(node: NimNode, str: string): bool {.compileTime.} =
  for n in node:
    if n.eqIdent str:
      return true

func isPub*(node: NimNode): bool {.compileTime.} =
  node.kind == nnkCommand and node[0].eqIdent"pub"

func insertSelf*(theProc, typeName: NimNode): NimNode {.compileTime.} =
  ## Inserts `self: typeName` in the 1st of theProc.params.
  result = theProc
  result.params.insert 1, newIdentDefs(ident"self", typeName)

template markWithPostfix*(node) =
  node = nnkPostfix.newTree(ident"*", node)

template newPragmaExpr*(node; pragma: string) =
  node = nnkPragmaExpr.newTree(
    node,
    nnkPragma.newTree(ident pragma)
  )
