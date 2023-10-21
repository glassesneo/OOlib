import
  std/algorithm,
  std/macrocache,
  std/macros,
  std/sequtils,
  std/strformat,
  ./class_util

from
  ../protocols/protocol_util import ProtocolTable

proc readBody(
    signature: var ClassSignature,
    body: NimNode
) {.compileTime.} =
  if body.kind == nnkEmpty:
    return

  for node in body:
    case node.kind
    of nnkVarSection:
      for identDefs in node:
        identDefs.inferValType()
        signature.variables.add decomposeIdentDefs(identDefs)

    of nnkProcDef:
      let theProc = copyNimTree(node)

      if theProc.isConstructor:
        signature.constructors.add theProc
        continue

      signature.routines.add theProc

    of nnkFuncDef, nnkMethodDef, nnkIteratorDef, nnkTemplateDef, nnkConverterDef:
      node.insertSelf(signature.className)
      signature.routines.add node

    else:
      discard

proc combineProtocolTupleTys(
    protocolNames: seq[NimNode]
): NimNode {.compileTime.} =
  result = nnkTupleTy.newNimNode()
  for name in protocolNames:
    let tupleTy = ProtocolTable[name.strVal].copyNimTree()

    for identDef in tupleTy:
      if identDef notin result[0..^1]:
        result.add identDef

proc checkIfVariableIsImplemented(
    variables: seq[NimNode],
    identDef: NimNode
) {.compileTime.} =
  for v in variables:

    if deletePragmasFromIdent(v)[0].eqIdent deletePragmasFromIdent(identDef)[0]:
      return

  let node = block:
    if identDef[0].kind == nnkPragmaExpr: identDef[0][0]
    else: identDef[0]

  error fmt"{node} is unimplemented", node

proc checkIfProcIsImplemented(
    procedures: seq[NimNode],
    identDef: NimNode
) {.compileTime.} =
  for p in procedures:
    let
      hasSameName = p.name.eqIdent identDef[0]
      hasSameParams = p.params.sameType identDef[1][0]
    if hasSameName and hasSameParams:
      return

  error fmt"{identDef[0]} is unimplemented", identDef[0]

template implementClass(className) =
  type className = ref object

proc addVariables(
    typeNode: NimNode,
    variables: seq[NimNode]
) {.compileTime.} =
  let recList = nnkRecList.newNimNode()
  for v in variables:
    recList.add v.deleteSpecialPragmasFromIdent()
  typeNode[0][2][0][2] = recList

proc defineType(signature: ClassSignature): NimNode {.compileTime.} =
  result = newStmtList()
  let typeSection = getAst implementClass(signature.className)

  if signature.isPublic:
    markWithAsterisk(typeSection)
  if signature.pragmas.len > 0:
    typeSection.addPragmas(signature.pragmas)

  typeSection.addVariables(signature.variables)

  result.add typeSection
  for routine in signature.routines:
    routine.insertSelf(signature.className)
    result.add routine

proc hasInitialPragma(identDef: NimNode): bool {.compileTime.} =
  identDef.expectLen(3)
  if not identDef.hasPragma:
    return
  for pragma in identDef[0][1]:
    if pragma.eqIdent"initial":
      return true

proc defineConstructorFromScratch(
    signature: ClassSignature
): NimNode {.compileTime.} =
  let
    constructorName = block:
      if signature.isPublic:
        ident"new".postfix"*"
      else:
        ident"new"

    constructorParams = @[signature.className] & newIdentDefs(
      ident"_", nnkCommand.newTree(
        ident"type",
        signature.className
      )
    ) & signature.variables
      .filterIt(not it.hasInitialPragma)
      .map(deleteAsteriskFromIdent)
      .map(deletePragmasFromIdent)

    constructorBody = newStmtList()

  constructorBody.add newVarStmt(
    ident"self", newCall(signature.className)
  )
  for identDef in signature.variables:
    let name = deleteSpecialPragmasFromIdent(identDef).deleteAsteriskFromIdent()[0]
    if identDef.hasInitialPragma:
      if identDef[2].kind == nnkEmpty:
        error "a member variables with {.initial.} must have a default value":
          identDef[2]
      let initial = identDef[2]
      constructorBody.add quote do:
        self.`name` = `initial`
      continue

    let v = name.basename
    constructorBody.add quote do:
      self.`name` = `v`

  constructorBody.add quote do:
    result = self

  result = newProc(
    name = constructorName,
    params = constructorParams,
    body = constructorBody
  )

proc defineConstructorFromBase(
    signature: ClassSignature,
    constructor: NimNode
) {.compileTime.} =
  constructor[0] = block:
    if constructor[0].kind == nnkPostfix:
      ident"new".postfix"*"
    else:
      ident"new"

  constructor.params[0] = signature.className
  constructor.params.insert 1, newIdentDefs(
    ident"_", nnkCommand.newTree(
      ident"type",
      signature.className
    )
  )

  if constructor.body[0].kind == nnkDiscardStmt:
    return

  constructor.body.insert(
    0, newVarStmt(ident"self", newCall(signature.className))
  )
  constructor.body.add quote do:
    result = self

proc defineConstructors(
    signature: var ClassSignature
) {.compileTime.} =
  for constructor in signature.constructors:
    signature.defineConstructorFromBase(constructor)

  signature.constructors.add(
    signature.defineConstructorFromScratch()
  )

proc newLambda(params: NimNode): NimNode {.compileTime.} =
  result = nnkLambda.newTree(
    newEmptyNode(),
    newEmptyNode(),
    newEmptyNode(),
    params,
    newEmptyNode(),
    newEmptyNode(),
    newStmtList()
  )

proc ConvertIdentDefIntoLambda(
    identDef: NimNode
): NimNode {.compileTime.} =
  result = newLambda(identDef[1].params)

  let call = newCall(
    identDef[0],
    ident"self"
  )
  for i in identDef[1].params[1..^1]:
    call.add i[0..^3]

  result[6].add call

proc defineConvertionProc(
    signature: ClassSignature,
    tupleTy: NimNode
): NimNode {.compileTime.} =
  let procBody = newStmtList(
    nnkReturnStmt.newTree(
      nnkTupleConstr.newNimNode()
    )
  )

  for identDef in tupleTy:
    if identDef[1].kind == nnkProcTy:
      procBody[0][0].add newColonExpr(
        a = identDef[0],
        b = ConvertIdentDefIntoLambda(identDef)
      )
    else:
      procBody[0][0].add newColonExpr(
        a = identDef[0],
        b = ident"self".newDotExpr(identDef[0])
      )

  result = newProc(
    name = ident"toProtocol",
    params = [
      tupleTy,
      newIdentDefs(ident"self", signature.className)
    ],
    body = procBody
  )

proc defineImplementClass*(
    signature: var ClassSignature,
    body: NimNode
): NimNode {.compileTime.} =
  signature.readBody(body)

  let tupleTy = combineProtocolTupleTys(signature.protocols)

  for identDef in tupleTy:
    if identDef[1].kind == nnkProcTy:
      signature.procedures.checkIfProcIsImplemented(identDef)
    else:
      signature.variables.checkIfVariableIsImplemented(identDef)

  result = defineType(signature)

  defineConstructors(signature)
  for constructor in signature.constructors.reversed:
    result.insert 1, constructor

  result.add defineConvertionProc(signature, tupleTy)
