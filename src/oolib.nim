import
  std/macros,
  oolib/[
    class_util,
    normal_class,
    distinct_class,
    named_tuple_class
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
