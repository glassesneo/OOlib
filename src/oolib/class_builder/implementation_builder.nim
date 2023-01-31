import
  std/macros,
  std/strformat,
  std/sugar,
  std/sequtils,
  ./builder,
  ../tmpl

type ImplementationBuilder* = ref object
  name, base, typeSection, constructor: NimNode
  isPublic: bool
  pragmas: seq[NimNode]
  variables, ignoredVariables, initialVariables, constants, routines: seq[NimNode]

proc new*(_: typedesc[ImplementationBuilder]): ImplementationBuilder {.compileTime.} =
  result = ImplementationBuilder()
  result.constructor = newEmptyNode()

func convertFuncToProcWithPragma(theFunc: NimNode): NimNode {.compileTime.} =
  ## Converts `func f()` to `proc f() {.noSideEffect.}`.
  theFunc.expectKind nnkFuncDef
  result = nnkProcDef.newNimNode()
  theFunc.copyChildrenTo result
  result.addPragma ident"noSideEffect"

proc createLambdaColonExpr(p: NimNode): NimNode {.compileTime.} =
  let lambdaProc = p.removeAsteriskFromProc()
  lambdaProc.params.del(idx = 1)
  let name = lambdaProc.name.copy
  lambdaProc.name = newEmptyNode()
  lambdaProc.body = newDotExpr(ident"self", name).newCall(
    lambdaProc.params[1..^1].mapIt(it[0])
  )
  result = newColonExpr(name, lambdaProc)

proc readHead(self: ImplementationBuilder; head: NimNode) {.compileTime.} =
  let node = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      self.isPublic = true
      head[1]
    else:
      head
  if node.kind == nnkCommand:
    if node[1].kind == nnkCommand:
      if node[1][1].kind == nnkPragmaExpr:
        self.name = node[0]
        self.base = node[1][1][0]
        self.pragmas = collect(for p in node[1][1][1]: p)
        return
      self.name = node[0]
      self.base = node[1][1]
  else:
    error "Unsupported syntax", node

proc readBody(self: ImplementationBuilder; body: NimNode) {.compileTime.} =
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        if ident"noNewDef" in self.pragmas and n.hasDefault:
          error "default values cannot be used with {.noNewDef.}", n
        n.inferValType()
        for d in n.decomposeIdentDefs():
          if d.hasPragma:
            if "initial" in d[0][1]:
              self.initialVariables.add d
            elif "ignored" in d[0][1]:
              self.ignoredVariables.add d
            else:
              self.variables.add d
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
          self.constructor = node
        else:
          error "Constructor already exists", node
      else:
        let theProc = node
        theProc.params.insert 1, newIdentDefs(ident"self", self.name)
        self.routines.add theProc
    of nnkFuncDef:
      let theProc = node.copy
      theProc.params.insert 1, newIdentDefs(ident"self", self.name)
      self.routines.add theProc.convertFuncToProcWithPragma()
    of nnkMethodDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      let theProc = node
      theProc.params.insert 1, newIdentDefs(ident"self", self.name)
      self.routines.add theProc
    else:
      discard

proc defineTypeSection(self: ImplementationBuilder) {.compileTime.} =
  self.typeSection = getAst defObj(self.name)
  if self.isPublic:
    self.typeSection[0][0] = self.typeSection[0][0].postfix "*"
  self.typeSection[0][0] = nnkPragmaExpr.newTree(
    self.typeSection[0][0],
    nnkPragma.newTree ident"pClass"
  )

proc defineConstructor(self: ImplementationBuilder) {.compileTime.} =
  if ident"noNewDef" in self.pragmas:
    return
  if self.constructor.kind == nnkEmpty:
    let args = (self.variables & self.ignoredVariables).map(simplifyIdentDefs)
    let name =
      if self.isPublic: nnkPostfix.newTree(ident"*", ident"new")
      else: ident"new"
    let params = self.name & (
      newIdentDefs(
        ident"_",
        nnkBracketExpr.newTree(ident"typedesc", self.name)
      ) & args
    )
    let body = generateConstructorBody(
      self.name,
      self.variables,
      self.initialVariables
    )
    self.constructor = newProc(name, params, body)

  else:
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

proc defineVariables(self: ImplementationBuilder) {.compileTime.} =
  self.typeSection[0][2][0][2] = (self.variables & self.ignoredVariables)
    .map(removeDefault).toRecList()

proc getResult(self: ImplementationBuilder): NimNode {.compileTime.} =
  result = newStmtList()
  result.add self.typeSection
  result.insert 1, self.constructor
  for r in self.routines:
    result.add r
  for c in self.constants:
    result.insert 1, generateRoutinesForConstant(self.name, c)

  let variableColonExpressions = self.variables
    .map(removeAsteriskFromIdent)
    .mapIt(newColonExpr(it[0], ident"self".newDotExpr it[0]))



  let proceduresColonExpressions = self.routines
    .filterIt(it.kind == nnkProcDef and "ignored" notin it[4])
    .map createLambdaColonExpr


  let converterBody = newStmtList(
    nnkReturnStmt.newTree(nnkTupleConstr.newNimNode().add(
        variableColonExpressions
    ).add(
      proceduresColonExpressions
    ))
  )
  let interfaceProc = newProc(ident"toInterface", [self.base], converterBody)
  interfaceProc.params.insert 1, newIdentDefs(ident"self", self.name)
  let compileProc = interfaceProc.copy
  if self.isPublic:
    interfaceProc.name = interfaceProc.name.postfix "*"
  for p in self.routines.filterIt(it.kind == nnkProcDef and "ignored" notin it[4]):
    var
      propertyNode = newDotExpr(self.base, p.name)
      errorStatement = newStrLitNode fmt"property `{p.name.strVal}` is not in the definition of {self.base.strVal}"
    result.add quote do:
      when not compiles(`propertyNode`):
        {.error: `errorStatement`.}

  result.add quote do:
    when compiles(`compileProc`):
      `interfaceProc`
    else:
      {.error: "Something went wrong".}

generateToInterface ImplementationBuilder
