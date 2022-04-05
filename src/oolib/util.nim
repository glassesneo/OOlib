{.experimental: "strictFuncs".}
import
  std/macros


func contains*(node: NimNode, str: string): bool {.compileTime.} =
  for n in node:
    if n.eqIdent str:
      return true


func isPub*(node: NimNode): bool {.compileTime.} =
  node.kind == nnkCommand and node[0].eqIdent"pub"


func decomposeDefsIntoVars*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      if v.kind == nnkPragmaExpr:
        result.add v[0]
        continue
      result.add v


template markWithPostfix*(node) =
  node = nnkPostfix.newTree(ident"*", node)


template newPragmaExpr*(node; pragma: string) =
  node = nnkPragmaExpr.newTree(
    node,
    nnkPragma.newTree(ident pragma)
  )
