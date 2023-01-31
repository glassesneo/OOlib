import
  std/macros,
  std/sequtils,
  std/sugar

type
  Builder* = tuple
    name, base, typeSection, constructor: NimNode
    isPublic: bool
    pragmas: seq[NimNode]
    variables, ignoredVariables, initialVariables, constants, routines: seq[NimNode]
    readHead: (head: NimNode) -> void
    readBody: (body: NimNode) -> void
    defineTypeSection: () -> void
    defineConstructor: () -> void
    defineVariables: () -> void
    getResult: () -> NimNode

  Director* = ref object
    builder: Builder

  BuilderConcept = concept b
    b.variables is seq[NimNode]
    b.ignoredVariables is seq[NimNode]
    b.initialVariables is seq[NimNode]

proc new*(_: typedesc[Director], builder: Builder): Director {.compileTime.} =
  Director(builder: builder)

proc build*(self: Director, head, body: NimNode): NimNode {.compileTime.} =
  self.builder.readHead(head)
  self.builder.readBody(body)
  self.builder.defineTypeSection()
  self.builder.defineConstructor()
  self.builder.defineVariables()
  result = self.builder.getResult()

proc allVariables*(builder: BuilderConcept): seq[NimNode] {.compileTime.} =
  builder.variables & builder.ignoredVariables & builder.initialVariables

func hasPragma*(node: NimNode): bool {.compileTime.} =
  ## `node` has to be `nnkIdentDefs or nnkConstDef`.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[0].kind == nnkPragmaExpr

func removeDefault*(def: NimNode): NimNode {.compileTime.} =
  def[^1] = newEmptyNode()
  return def

proc removeAsteriskFromIdent*(def: NimNode): NimNode {.compileTime.} =
  result = nnkIdentDefs.newNimNode()
  for id in def[0..^3]:
    result.add if id.kind == nnkPostfix and id[0].eqIdent"*": id[1]
      else: id
  result.add(def[^2], def[^1])

proc removeAsteriskFromProc*(theProc: NimNode): NimNode {.compileTime.} =
  result = theProc.copy
  result[0] =
    if theProc[0].kind == nnkPostfix and theProc[0][0].eqIdent"*": theProc[0][1]
    else: theProc[0]

proc removePragmasFromIdent*(def: NimNode): NimNode {.compileTime.} =
  result = nnkIdentDefs.newNimNode()
  for id in def[0..^3]:
    result.add if id.kind == nnkPragmaExpr: id[0]
      else: id
  result.add(def[^2], def[^1])

proc simplifyIdentDefs*(def: NimNode): NimNode {.compileTime.} =
  result = def.removePragmasFromIdent().removeAsteriskFromIdent()

func generateConstructorBody*(
    name: NimNode,
    variables, initialVariables: seq[NimNode]
): NimNode {.compileTime.} =
  result = newStmtList(newVarStmt(ident"self", newCall name))
  for v in variables.mapIt(it[0]):
    result.insert 1, quote do:
      self.`v` = `v`
  for def in initialVariables.map(simplifyIdentDefs):
    let
      v = def[0]
      initial = def[^1]
    result.insert 1, quote do:
      self.`v` = `initial`
  result.add quote do: result = self

func generateRoutinesForConstant*(name, constant: NimNode): NimNode {.compileTime.} =
  let
    constantName = constant[0]
    constantType = constant[1]
    constantValue = constant[^1]
  let constantTemplate = quote do:
    template `constantName`(self: typedesc[`name`]): untyped =
      `constantValue`

  let constantMethod = quote do:
    method `constantName`(self: `name`): `constantType` {.optBase.} =
      return `constantValue`

  result = newStmtList().add(constantTemplate).add(constantMethod)

func isSuperFunc(node: NimNode): bool {.compileTime.} =
  ## Returns whether struct is `super.f()` or not.
  node.kind == nnkCall and
  node[0].kind == nnkDotExpr and
  node[0][0].eqIdent"super"

proc replaceSuper*(node: NimNode): NimNode =
  ## Replaces `super.f()` with `procCall Base(self).f()`.
  result = node
  if node.isSuperFunc:
    return newTree(
      nnkCommand,
      ident "procCall",
      copyNimTree(node)
    )
  for i, n in node:
    result[i] = n.replaceSuper()

func isConstructor*(node: NimNode): bool {.compileTime.} =
  ## `node` has to be `nnkProcDef`.
  node.expectKind {nnkProcDef, nnkMethodDef}
  node[0].kind == nnkAccQuoted and node.name.eqIdent"new"

func contains*(node: NimNode, str: string): bool {.compileTime.} =
  for n in node:
    if n.eqIdent str:
      return true

func decomposeIdentDefs*(defs: NimNode): seq[NimNode] {.compileTime.} =
  result = collect:
    for v in defs[0..^3]:
      newIdentDefs(v, defs[^2], defs[^1])

func hasDefault*(node: NimNode): bool {.compileTime.} =
  node.expectKind {nnkIdentDefs, nnkConstDef}
  not (node.last.kind == nnkEmpty)

func inferValType*(node: NimNode) {.compileTime.} =
  ## Infers type from default if a type annotation is empty.
  node.expectKind {nnkIdentDefs, nnkConstDef}
  node[^2] = node[^2] or newCall(ident"typeof", node[^1])

func toRecList*(s: seq[NimNode]): NimNode {.compileTime.} =
  result = nnkRecList.newNimNode()
  for def in s:
    result.add def

proc convertPragmasToSeq*(pragmas: NimNode): seq[NimNode] {.compileTime.} =
  pragmas.expectKind nnkPragma

template generateToInterface*(t) =
  proc toInterface*(self: t): Builder {.compileTime.} =
    result = (
      name: self.name,
      base: self.base,
      typeSection: self.typeSection,
      constructor: self.constructor,
      isPublic: self.isPublic,
      pragmas: self.pragmas,
      variables: self.variables,
      ignoredVariables: self.ignoredVariables,
      initialVariables: self.initialVariables,
      constants: self.constants,
      routines: self.routines,
      readHead: proc(head: NimNode) = self.readHead(head),
      readBody: proc(body: NimNode) = self.readBody(body),
      defineTypeSection: () => self.defineTypeSection(),
      defineConstructor: () => self.defineConstructor(),
      defineVariables: () => self.defineVariables(),
      getResult: () => self.getResult()
    )
