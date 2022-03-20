{.experimental: "strictFuncs".}
import macros, sequtils
import tmpl


using
  node, constructor, theProc, typeName, baseName: NimNode
  isPub: bool


func contains*(node; str: string): bool {.compileTime.} =
  for n in node:
    if n.eqIdent str:
      return true


func isDistinct*(node): bool {.compileTime.} =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy


func isPub*(node): bool {.compileTime.} =
  node.kind == nnkCommand and node[0].eqIdent"pub"


func isInheritance*(node): bool {.compileTime.} =
  node.kind == nnkInfix and node[0].eqIdent"of"


func isSuperFunc*(node): bool {.compileTime.} =
  ## Returns whether struct is `super.f()` or not.
  node.kind == nnkCall and
  node[0].kind == nnkDotExpr and
  node[0][0].eqIdent"super"


func hasAsterisk*(node): bool {.compileTime.} =
  node.len > 0 and
  node.kind == nnkPostfix and
  node[0].eqIdent"*"


func isConstructor*(node): bool {.compileTime.} =
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"


func isEmpty*(node): bool {.compileTime.} =
  node.kind == nnkEmpty


func hasDefault*(node): bool {.compileTime.} =
  ## `node` has to be `nnkIdentDefs` or `nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  not node.last.isEmpty


func inferValType*(node: NimNode) {.compileTime.} =
  ## Infers type from default if a type annotation is empty.
  ## `node` has to be `nnkIdentDefs` or `nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[^2] = node[^2] or newCall(ident"typeof", node[^1])


func insertIn1st*(node; inserted: NimNode) {.compileTime.} =
  node.insert 1, inserted


func insertSelf*(theProc; typeName): NimNode {.compileTime.} =
  ## Inserts `self: typeName` in the 1st of theProc.params.
  result = theProc
  result.params.insertIn1st newIdentDefs(ident "self", typeName)


func removeSelf(theProc): NimNode {.compileTime.} =
  ## Removes `self: typeName` from the 1st of theProc.params.
  result = theProc.copy
  result.params.del(1, 1)


proc replaceSuper*(node): NimNode =
  ## Replaces `super.f()` with `procCall Base(self).f()`.
  result = node
  if node.isSuperFunc:
    result = newTree(
      nnkCommand,
      ident "procCall",
      copyNimTree(node)
    )
    return
  for i, n in node:
    result[i] = n.replaceSuper()


func newSuperStmt(baseName): NimNode {.compileTime.} =
  ## Generates `var super = Base(self)`.
  newVarStmt ident"super", newCall(baseName, ident "self")


func insertSuperStmt*(theProc; baseName): NimNode {.compileTime.} =
  ## Inserts `var super = Base(self)` in the 1st line of `theProc.body`.
  result = theProc
  result.body.insert 0, newSuperStmt(baseName)


func delDefaultValue*(node): NimNode {.compileTime.} =
  result = node
  result[^1] = newEmptyNode()


func newPostfix*(node): NimNode {.compileTime.} =
  nnkPostfix.newTree ident"*", node


func newSelfStmt(typeName): NimNode {.compileTime.} =
  ## Generates `var self = typeName()`.
  newVarStmt ident"self", newCall(typeName)


func newResultAsgn(rhs: string): NimNode {.compileTime.} =
  newAssignment ident"result", ident rhs


func toRecList*(s: seq[NimNode]): NimNode {.compileTime.} =
  result = nnkRecList.newNimNode()
  for def in s:
    result.add def


func toSeq*(node: NimNode): seq[string] {.compileTime.} =
  node.expectKind nnkPragma
  for s in node:
    result.add s.strVal


func newVarsColonExpr*(v: NimNode): NimNode {.compileTime.} =
  newColonExpr(v, newDotExpr(ident"self", v))


func newLambdaColonExpr*(theProc: NimNode): NimNode {.compileTime.} =
  ## Generates `name: proc() = self.name()`.
  var lambdaProc = theProc.removeSelf()
  let name = lambdaProc[0]
  lambdaProc[0] = newEmptyNode()
  lambdaProc.body = newDotExpr(ident"self", name).newCall(
    lambdaProc.params[1..^1].mapIt(it[0])
  )
  result = newColonExpr(name, lambdaProc)


func rmAsterisk(node): NimNode {.compileTime.} =
  result = node
  if node.hasAsterisk:
    result = node[1]


proc rmAsteriskFromIdent*(def: NimNode): NimNode {.compileTime.} =
  result = nnkIdentDefs.newNimNode()
  for v in def[0..^3]:
    result.add v.rmAsterisk
  result.add(def[^2], def[^1])


func decomposeDefsIntoVars*(s: seq[NimNode]): seq[NimNode] {.compileTime.} =
  for def in s:
    for v in def[0..^3]:
      result.add v


proc genNewBody*(typeName; vars: seq[NimNode]): NimNode {.compileTime.} =
  result = newStmtList newSelfStmt(typeName)
  for v in vars:
    result.insertIn1st getAst(asgnWith v)
  result.add newResultAsgn"self"


func replaceReturnTypeWith*(
    constructor,
    typeName
): NimNode {.compileTime.} =
  result = constructor
  result.params[0] = typeName


proc insertArgs*(
    constructor;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  ## Inserts `vars` to constructor args.
  result = constructor
  for v in vars[0..^1]:
    result.params.insertIn1st(v)


func insertBody*(
    constructor;
    vars: seq[NimNode]
): NimNode {.compileTime.} =
  result = constructor
  if result.body[0].kind == nnkDiscardStmt:
    return
  result.body.insert 0, newSelfStmt(result.params[0])
  for v in vars.decomposeDefsIntoVars():
    result.body.insertIn1st getAst(asgnWith v)
  result.body.add newResultAsgn"self"


# Because it's used in template, must be exported.
func markWithAsterisk*(theProc): NimNode {.compileTime.} =
  result = theProc
  result.name = newPostfix(theProc.name)


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
        nnkIdentDefs.newTree(
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
      nnkStmtList.newTree(
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
        nnkIdentDefs.newTree(
          newIdentNode("self"),
          newIdentNode(className),
          newEmptyNode(),
      )
    ),
      nnkPragma.newTree(
        newIdentNode("optBase")
      ),
      newEmptyNode(),
      nnkStmtList.newTree(
        nnkReturnStmt.newTree(
          node[^1]
        )
      )
    ),
  )
