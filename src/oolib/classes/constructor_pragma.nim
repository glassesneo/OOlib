import
  std/macros,
  std/sequtils,
  ./class_util

proc readTypeSection*(typeDef: NimNode): ClassSignature {.compileTime.} =
  typeDef[2].expectKind {nnkRefTy, nnkObjectTy}

  case typeDef[0].kind
  of nnkPragmaExpr:
    result.pragmas = typeDef[0][1][0..^1]
    if typeDef[0][0].kind == nnkPostfix:
      result.isPublic = true
      result.className = unpackPostfix(typeDef[0][0]).node
    else:
      result.className = typeDef[0][0]

  of nnkPostfix:
    result.isPublic = true
    result.className = unpackPostfix(typeDef[0]).node

  of nnkIdent:
    result.className = typeDef[0]

  else:
    error "Unsupported syntax", typeDef[0]

  let recList = block:
    if typeDef[2].kind == nnkRefTy:
      typeDef[2][0][2]
    else:
      typeDef[2][2]

  if recList.kind == nnkEmpty:
    error "There is no variable in the type definition", typeDef

  for identDefs in recList:
    result.variables.add decomposeIdentDefs(identDefs)

proc hasInitialPragma(identDef: NimNode): bool {.compileTime.} =
  identDef.expectLen(3)
  if not identDef.hasPragma:
    return
  for pragma in identDef[0][1]:
    if pragma.eqIdent"initial":
      return true

proc defineConstructorFromScratch*(
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

    constructorBody = newStmtList()

  constructorBody.add newVarStmt(
    ident"self", newCall(signature.className)
  )
  for identDef in signature.variables:
    let v = identDef.deleteSpecialPragmasFromIdent()[0]
    if identDef.hasInitialPragma:
      if identDef[2].kind == nnkEmpty:
        error "a member variables with {.initial.} must have a default value":
          identDef[2]
      let initial = identDef[2]
      constructorBody.add quote do:
        self.`v` = `initial`
      continue

    constructorBody.add quote do:
      self.`v` = `v`

  constructorBody.add quote do:
    result = self

  result = newProc(
    name = constructorName,
    params = constructorParams,
    body = constructorBody
  )
