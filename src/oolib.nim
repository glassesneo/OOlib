import
  std/macrocache,
  std/macros,
  std/strformat,
  oolib/classes/[
    class_util,
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

    for protocol in signature.protocols:
      if not ProtocolTable.hasKey(protocol.strVal):
        error fmt"Protocol {protocol} doesn't exist", protocol

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

macro protocol*(head: untyped; body: untyped = newEmptyNode()): untyped =
  var signature: ProtocolSignature

  signature.protocolName = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      signature.isPublic = true
      head[1]
    else:
      head

  let tupleTy = nnkTupleTy.newNimNode()

  for v in signature.variables:
    tupleTy.add v

  for p in signature.procedures:
    tupleTy.add convertIntoIdentDef(p)

  ProtocolTable[signature.protocolName.strVal] = tupleTy

  result = signature.defineProtocol(body)
