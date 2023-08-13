import
  std/sugar,
  std/macros,
  std/sequtils,
  ./builder,
  ../tmpl

type InheritanceBuilder* = ref object
  name, base, typeSection, constructor: NimNode
  isPublic: bool
  pragmas: seq[NimNode]
  variables, ignoredVariables, initialVariables, constants, routines: seq[NimNode]

proc new*(_: typedesc[InheritanceBuilder]): InheritanceBuilder {.compileTime.} =
  result = InheritanceBuilder()
  result.constructor = newEmptyNode()

proc readHead(self: InheritanceBuilder; head: NimNode) {.compileTime.} =
  let node = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      self.isPublic = true
      head[1]
    else:
      head
  if node.kind != nnkInfix:
    error "Unsupported syntax", node

  # class A of B {.pragma.}
  let headNodes = unpackInfix node

  if headNodes.right.kind == nnkPragmaExpr:
    self.name = headNodes.left
    self.base = headNodes.right.basename
    self.pragmas = collect(for p in headNodes.right[1]: p)
    return

  # class A of B
  self.name = headNodes.left
  self.base = headNodes.right

proc readBody(self: InheritanceBuilder; body: NimNode) {.compileTime.} =
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if ident"noNewDef" in self.pragmas and n.hasDefault:
          error "default values cannot be used with {.noNewDef.}", n
        if n.hasPragma and "ignored" in n[0][1]:
          error "{.ignored.} pragma cannot be used in non-implemented classes"
        n.inferValType()
        for d in n.decomposeIdentDefs():
          if d.hasPragma and "initial" in d[0][1]:
            self.initialVariables.add d
          else:
            self.variables.add d
    of nnkConstSection:
      for n in node:
        if not n.hasDefault:
          error "A constant must have a value", node
        n.inferValType()
        for d in n.decomposeIdentDefs():
          if d.hasPragma and "initial" in d[0][1]:
            error "{.initial.} pragma cannot be used with constant", d
          else:
            self.constants.add d
    of nnkProcDef:
      if node.isConstructor:
        if self.constructor.kind == nnkEmpty:
          self.constructor = node.replaceSuper()
          self.constructor.body.insert 0, newVarStmt(
            ident"super", newCall(self.base, ident"self")
          )
        else:
          error "Constructor already exists", node
      else:
        let theProc = node
        theProc.params.insert 1, newIdentDefs(ident"self", self.name)
        self.routines.add theProc
    of nnkMethodDef:
      if node.isConstructor:
        if self.constructor.kind == nnkEmpty:
          self.constructor = node.replaceSuper()
          self.constructor.body.insert 0, newVarStmt(
            ident"super", newCall(self.base, ident"self")
          )
        else:
          error "Constructor already exists", node
      else:
        let theProc = node
        theProc.body = replaceSuper(theProc.body)
        theProc.params.insert 1, newIdentDefs(ident"self", self.name)
        theProc.body.insert 0, newVarStmt(
          ident"super", newCall(self.base, ident"self")
        )
        self.routines.add theProc
    of nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      node.params.insert 1, newIdentDefs(ident"self", self.name)
      self.routines.add node
    else:
      discard

proc defineTypeSection(self: InheritanceBuilder) {.compileTime.} =
  self.typeSection = getAst defObjWithBase(self.name, self.base)
  if self.isPublic:
    self.typeSection[0][0] = nnkPostfix.newTree(ident"*", self.typeSection[0][0])
  self.typeSection[0][0] = nnkPragmaExpr.newTree(
    self.typeSection[0][0],
    nnkPragma.newTree ident"pClass"
  )

proc defineConstructor(self: InheritanceBuilder) {.compileTime.} =
  if self.constructor.kind != nnkEmpty and ident"noNewDef" notin self.pragmas:
    let args = (self.variables & self.ignoredVariables)
      .filter(hasDefault)
      .map(simplifyIdentDefs)

    self.constructor.name =
      if self.isPublic: nnkPostfix.newTree(ident"*", ident"new")
      else: ident"new"
    self.constructor.params[0] = self.name
    for arg in args:
      self.constructor.params.add arg
    self.constructor.params.insert 1, newIdentDefs(
      ident"_", nnkBracketExpr.newTree(
        ident"typedesc",
        self.name
      )
    )
    if self.constructor.body[0].kind == nnkDiscardStmt:
      return
    self.constructor.body.insert 0, newVarStmt(
      ident"self", newCall self.name
    )
    for v in args.mapIt(it[0]):
      self.constructor.body.insert 1, quote do: self.`v` = `v`
    for def in self.initialVariables.map(simplifyIdentDefs):
      let
        v = def[0]
        initial = def[^1]
      self.constructor.body.insert 1, quote do: self.`v` = `initial`
    self.constructor.body.add quote do: result = self

proc defineVariables(self: InheritanceBuilder) {.compileTime.} =
  self.typeSection[0][2][0][2] = self.allVariables.map(removeDefault).toRecList()

proc getResult(self: InheritanceBuilder): NimNode {.compileTime.} =
  result = newStmtList()
  result.add self.typeSection
  result.insert 1, self.constructor
  for r in self.routines:
    result.add r
  for c in self.constants:
    result.insert 1, generateRoutinesForConstant(self.name, c)

generateToInterface InheritanceBuilder
