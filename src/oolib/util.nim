{.experimental: "strictFuncs".}
import
  std/macros


func contains*(node: NimNode, str: string): bool {.compileTime.} =
  for n in node:
    if n.eqIdent str:
      return true


func isPub*(node: NimNode): bool {.compileTime.} =
  node.kind == nnkCommand and node[0].eqIdent"pub"
