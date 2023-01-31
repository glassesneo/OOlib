import
  std/sugar,
  std/macros,
  ./builder,
  ../tmpl

type DistinctBuilder* = ref object
  name, base, typeSection, constructor: NimNode
  isPublic: bool
  pragmas: seq[NimNode]
  variables, ignoredVariables, initialVariables, constants, routines: seq[NimNode]

proc new*(_: typedesc[DistinctBuilder]): DistinctBuilder {.compileTime.} =
  result = DistinctBuilder()
  result.constructor = newEmptyNode()

proc readHead(self: DistinctBuilder; head: NimNode) {.compileTime.} =
  let node = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      self.isPublic = true
      head[1]
    else:
      head
  case node.kind
  of nnkCall:
    if node[1].kind == nnkDistinctTy:
      # class A(distinct B)
      self.name = node[0]
      self.base = node[1][0]
  of nnkPragmaExpr:
    if node[0].kind == nnkCall and node[0][1].kind == nnkDistinctTy:
      self.name = node[0][0]
      self.base = node[0][1][0]
      self.pragmas = collect(for p in node[1]: p)
    else:
      error "Unsupported syntax", node
  else:
    error "Unsupported syntax", node

proc readBody(self: DistinctBuilder; body: NimNode) {.compileTime.} =
  for node in body:
    case node.kind
    of nnkVarSection:
      error "Distinct type cannot have variables", node
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
    of nnkProcDef, nnkMethodDef, nnkFuncDef, nnkIteratorDef, nnkConverterDef, nnkTemplateDef:
      let theProc = node
      theProc.params.insert 1, newIdentDefs(ident"self", self.name)
      self.routines.add theProc
    else:
      discard

proc defineTypeSection(self: DistinctBuilder) {.compileTime.} =
  self.typeSection = getAst defDistinct(self.name, self.base)
  if self.isPublic:
    self.typeSection[0][0][0] = self.typeSection[0][0][0].postfix "*"
  if ident"open" in self.pragmas:
    self.typeSection[0][0][1][0] = ident"inheritable"
    self.typeSection[0][0][1].add ident"pClass"

proc defineConstructor(self: DistinctBuilder) {.compileTime.} =
  discard

proc defineVariables(self: DistinctBuilder) {.compileTime.} =
  discard

proc getResult(self: DistinctBuilder): NimNode {.compileTime.} =
  result = newStmtList()
  result.add self.typeSection
  result.insert 1, self.constructor
  for r in self.routines:
    result.add r
  for c in self.constants:
    result.insert 1, generateRoutinesForConstant(self.name, c)

generateToInterface DistinctBuilder
