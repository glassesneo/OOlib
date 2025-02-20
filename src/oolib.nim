import
  std/macrocache,
  std/macros,
  std/typetraits,
  oolib/classes/[
    class_util,
    constructor_pragma,
    distinct_class,
    implement_class,
    named_tuple_class,
    normal_class
  ],
  oolib/protocols/[
    protocol_core,
    protocol_util
  ]

proc classify(
    signature: var ClassSignature,
    definingNode: NimNode
) {.compileTime.} =
  case definingNode.kind
  of nnkIdent:
    # class A
    signature.className = definingNode
    signature.classKind = NormalClass

  of nnkCall:
    if definingNode.len == 2:
      case definingNode[1].kind
      of nnkDistinctTy:
        # class A(distinct B)
        signature.className = definingNode[0]
        signature.baseName = definingNode[1][0]
        signature.classKind = DistinctClass

      of nnkTupleClassTy:
        # class A(tuple)
        signature.className = definingNode[0]
        signature.classKind = NamedTupleClass

      else:
        error "Unsupported syntax", definingNode[1]

    else:
      error "Unsupported syntax", definingNode

  of nnkCommand:
    if not definingNode.isImplement:
      error "Unsupported syntax", definingNode

    signature.className = definingNode[0]
    let protocols = block:
      if definingNode[1][1].kind == nnkPragmaExpr:
        signature.pragmas.add definingNode[1][1][1][0..^1]
        definingNode[1][1][0]
      else:
        definingNode[1][1]

    if protocols.kind == nnkIdent:
      signature.protocols.add protocols
    else:
      signature.protocols = protocols[0..^1]

    signature.classKind = ImplementClass

  of nnkPragmaExpr:
    if signature.pragmas.len != 0:
      error "Unsupported syntax", definingNode

    # class ... {.pragma.}
    signature.pragmas.add definingNode[1][0..^1]
    signature.classify(definingNode[0])

  else:
    error "Unsupported syntax", definingNode

macro class*(head: untyped; body: untyped = newEmptyNode()): untyped =
  var signature: ClassSignature

  let definingNode = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      signature.isPublic = true
      head[1]
    else:
      head

  signature.classify(definingNode)

  result = case signature.classKind
    of NormalClass:
      signature.defineNormalClass(body)
    of DistinctClass:
      signature.defineDistinctClass(body)
    of NamedTupleClass:
      signature.defineNamedTupleClass(body)
    of ImplementClass:
      signature.defineImplementClass(body)

macro construct*(typeDef: untyped): untyped =
  result = typeDef

  var signature = readTypeSection(typeDef)

  let rightHand = nnkStmtListType.newNimNode()
  block:
    let internalBody = block:
      if typeDef[2].kind == nnkRefTy:
        let body = quote do:
          type Internal = ref object
          Internal
        body[0][0][2][0][2] = nnkRecList.newNimNode()
        for v in signature.variables:
          body[0][0][2][0][2].add class_util.deletePragmasFromIdent(v)
        body

      else:
        let body = quote do:
          type Internal = object
          Internal
        body[0][0][2][2] = nnkRecList.newNimNode()
        for v in signature.variables:
          body[0][0][2][2].add class_util.deletePragmasFromIdent(v)
        body

    internalBody.insert 1, defineConstructorFromScratch(signature)
    internalBody.copyChildrenTo(rightHand)

  result = typeDef
  result[2] = rightHand

macro protocol*(head: untyped; body: untyped = newEmptyNode()): untyped =
  var signature: ProtocolSignature

  signature.protocolName = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      signature.isPublic = true
      head[1]
    else:
      head

  result = signature.defineProtocol(body)

  let tupleTy = nnkTupleTy.newNimNode()

  for v in signature.variables:
    tupleTy.add v

  for p in signature.procedures:
    tupleTy.add convertIntoIdentDef(p)

  ProtocolTable[signature.protocolName.strVal] = tupleTy

macro protocoled*(typeDef: untyped): untyped =
  let protocolName = typeDef[0][0]
  typeDef[0] = protocolName

  result = typeDef

  ProtocolTable[protocolName.basename.strVal] = typeDef[2]

template derive*(protocols: seq[string]) {.pragma.}

macro isInstanceOf*(v: typed, T: typedesc): bool =
  result = quote do:
    when ProtocolTable.hasKey(astToStr(`T`)):
      when compiles(`v`.toProtocol()):
        (`v`.toProtocol().type is `T`) or (`T`.name in `v`.getCustomPragmaVal(derive))
      else:
        false
    else:
      `v`.type is `T`

macro pick*(t, P: untyped): tuple =
  let tupleTy = ProtocolTable[P.strVal]
  result = nnkTupleConstr.newTree()
  for v in tupleTy:
    let name = v[0]
    result.add newColonExpr(name, t.newDotExpr(name))

