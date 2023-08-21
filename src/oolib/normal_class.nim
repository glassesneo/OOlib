import
  std/macros,
  ./class_util

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
        signature.variables.add decomposeIdentDefs(identDefs)

    of nnkProcDef:
      let theProc = copyNimTree(node)

      if theProc.isConstructor:
        signature.constructors.add theProc
        continue

      theProc.insertSelf(signature.className)
      signature.routines.add theProc

    of nnkFuncDef, nnkMethodDef, nnkIteratorDef, nnkTemplateDef, nnkConverterDef:
      node.insertSelf(signature.className)
      signature.routines.add node

    else:
      discard

template normalClass(className) =
  type className = ref object

proc addVariables(
    typeNode: NimNode,
    variables: seq[NimNode]
) {.compileTime.} =
  let recList = nnkRecList.newNimNode()
  for v in variables:
    recList.add v
  typeNode[0][2][0][2] = recList

proc defineType(signature: ClassSignature): NimNode {.compileTime.} =
  result = newStmtList()
  let typeSection = getAst normalClass(signature.className)

  if signature.isPublic:
    markWithAsterisk(typeSection)
  if signature.pragmas.len > 0:
    typeSection.addPragmas(signature.pragmas)

  typeSection.addVariables(signature.variables)

  result.add typeSection
  for routine in signature.routines:
    result.add routine

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

    constructorBody = newStmtList()

  constructorBody.add newVarStmt(
    ident"self", newCall(signature.className)
  )
  for identDef in signature.variables:
    let v = identDef[0]
    constructorBody.add quote do:
      self.`v` = `v`
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

proc defineNormalClass*(
    signature: var ClassSignature,
    body: NimNode
): NimNode {.compileTime.} =
  signature.readBody(body)

  result = defineType(signature)

  defineConstructors(signature)
  for constructor in signature.constructors:
    result.add(constructor)
