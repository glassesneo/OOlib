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
        error "Named tuple class cannot have constructor"

      theProc.insertSelf(signature.className)
      signature.routines.add theProc

    of nnkFuncDef, nnkIteratorDef, nnkTemplateDef, nnkConverterDef:
      node.insertSelf(signature.className)
      signature.routines.add node

    else:
      discard

template namedTupleClass(className) =
  type className = tuple

proc addVariables(
    typeNode: NimNode,
    variables: seq[NimNode]
) {.compileTime.} =
  let tupleTy = nnkTupleTy.newNimNode()
  for v in variables:
    tupleTy.add v
  typeNode[0][2] = tupleTy

proc defineType(signature: ClassSignature): NimNode {.compileTime.} =
  result = newStmtList()
  let typeSection = getAst namedTupleClass(signature.className)

  if signature.isPublic:
    markWithAsterisk(typeSection)
  if signature.pragmas.len > 0:
    typeSection.addPragmas(signature.pragmas)

  typeSection.addVariables(signature.variables)

  result.add typeSection
  for routine in signature.routines:
    result.add routine

proc defineNamedTupleClass*(
    signature: var ClassSignature,
    body: NimNode
): NimNode {.compileTime.} =
  signature.readBody(body)
  result = defineType(signature)
