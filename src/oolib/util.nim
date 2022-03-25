{.experimental: "strictFuncs".}
import macros


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


func newPostfix*(node): NimNode {.compileTime.} =
  nnkPostfix.newTree ident"*", node


func decomposeDefsIntoVars*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      if v.kind == nnkPragmaExpr:
        result.add v[0]
        continue
      result.add v


func newPragmaExpr*(node; pragma: string): NimNode {.compileTime.} =
  result = nnkPragmaExpr.newTree(
    node,
    nnkPragma.newTree(ident pragma)
  )


proc genConstant*(className: string; node: NimNode): NimNode {.compileTime.} =
  # generate both a template for use with typedesc and a method for dynamic dispatch
  #
  # dumpAstGen:
  #   template speed*(self: typedesc[A]): untyped = 10.0f
  #   method speed*(self: A): typeof(10.0f) {.optBase.} = 10.0f

  nnkStmtList.newTree(
    # template
    nnkTemplateDef.newTree(
      node[0],
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        newIdentNode("untyped"),
        newIdentDefs(
          newIdentNode("self"),
          nnkBracketExpr.newTree(
            newIdentNode("typedesc"),
            newIdentNode(className)
      ),
      newEmptyNode()
    )
      ),
      newEmptyNode(),
      newEmptyNode(),
      newStmtList(
        node[^1]
      )
    ),
    # method
    nnkMethodDef.newTree(
      node[0],
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        node[1],
        newIdentDefs(
          newIdentNode("self"),
          newIdentNode(className),
          newEmptyNode(),
      )
    ),
      nnkPragma.newTree(
        newIdentNode("optBase")
      ),
      newEmptyNode(),
      newStmtList(
        nnkReturnStmt.newTree(
          node[^1]
        )
      )
    ),
  )
