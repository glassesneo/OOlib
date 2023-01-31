import
  std/sequtils,
  std/sugar,
  std/macros,
  ./builder,
  ../tmpl

type AliasBuilder* = ref object
  name, base, typeSection, constructor: NimNode
  isPublic: bool
  pragmas: seq[NimNode]
  variables, ignoredVariables, initialVariables, constants, routines: seq[NimNode]

proc new*(_: typedesc[AliasBuilder]): AliasBuilder {.compileTime.} =
  result = AliasBuilder()
  result.constructor = newEmptyNode()

proc readHead(self: AliasBuilder; head: NimNode) {.compileTime.} =
  let node = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      self.isPublic = true
      head[1]
    else:
      head
  case node.kind
  of nnkCall:
    self.name = node[0]
    self.base = node[1]
  of nnkPragmaExpr:
    if node[0].kind == nnkCall:
      self.name = node[0][0]
      self.base = node[0][1]
      self.pragmas = collect(for p in node[1]: p)
    else:
      error "Unsupported syntax", node
  else:
    error "Unsupported syntax", node

proc readBody(self: AliasBuilder; body: NimNode) {.compileTime.} =
  for node in body:
    case node.kind
    of nnkVarSection:
      if self.base.repr != "tuple":
        error "Type alias cannot have variables", node
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
      if self.base.eqIdent"tuple" and node.isConstructor:
        if self.constructor.kind == nnkEmpty:
          self.constructor = node
        else:
          error "Constructor already exists", node
      else:
        let theProc = node
        theProc.params.insert 1, newIdentDefs(ident"self", self.name)
        self.routines.add theProc
    of nnkMethodDef, nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      let theProc = node
      theProc.params.insert 1, newIdentDefs(ident"self", self.name)
      self.routines.add theProc
    else:
      discard

proc defineTypeSection(self: AliasBuilder) {.compileTime.} =
  self.typeSection = getAst defAlias(self.name, self.base)
  if self.isPublic:
    self.typeSection[0][0] = self.typeSection[0][0].postfix "*"
  self.typeSection[0][0] = nnkPragmaExpr.newTree(
    self.typeSection[0][0],
    nnkPragma.newTree ident"pClass"
  )

proc defineConstructor(self: AliasBuilder) {.compileTime.} =
  discard

proc defineVariables(self: AliasBuilder) {.compileTime.} =
  discard

proc getResult(self: AliasBuilder): NimNode {.compileTime.} =
  result = newStmtList()
  result.add self.typeSection
  if self.variables.len != 0:
    result[0][0][2] = nnkTupleTy.newTree(
      self.variables.map(removeDefault)
    )
  result.insert 1, self.constructor
  for r in self.routines:
    result.add r
  for c in self.constants:
    result.insert 1, generateRoutinesForConstant(self.name, c)

generateToInterface AliasBuilder
