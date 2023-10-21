import
  std/algorithm,
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
      error "Distinct type cannot have a member variable", node

    of nnkProcDef:
      let theProc = copyNimTree(node)

      if theProc.isConstructor:
        signature.constructors.add theProc
        continue

      theProc.insertSelf(signature.className)
      signature.routines.add theProc

    of nnkFuncDef, nnkIteratorDef, nnkTemplateDef, nnkConverterDef:
      node.insertSelf(signature.className)
      signature.routines.add node

    else:
      discard

template distinctClass(className, baseName) =
  type className = distinct baseName

proc defineType(signature: ClassSignature): NimNode {.compileTime.} =
  result = newStmtList()
  let typeSection = getAst distinctClass(
    signature.className, signature.baseName
  )

  if signature.isPublic:
    markWithAsterisk(typeSection)
  if signature.pragmas.len > 0:
    typeSection.addPragmas(signature.pragmas)

  result.add typeSection
  for routine in signature.routines:
    result.add routine

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
    signature: ClassSignature
) {.compileTime.} =
  for constructor in signature.constructors:
    signature.defineConstructorFromBase(constructor)

proc defineDistinctClass*(
    signature: var ClassSignature,
    body: NimNode
): NimNode {.compileTime.} =
  signature.readBody(body)

  result = defineType(signature)

  defineConstructors(signature)
  for constructor in signature.constructors.reversed:
    result.insert 1, constructor
