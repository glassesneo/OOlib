import
  std/macros,
  std/sugar,
  types,
  util

func isDistinct(node: NimNode): bool {.compileTime.} =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy

func isInheritance(node: NimNode): bool {.compileTime.} =
  node.kind == nnkInfix and node[0].eqIdent"of"

func hasGenerics(node: NimNode): bool {.compileTime.} =
  node.kind == nnkBracketExpr and
  node[0].kind == nnkIdent and
  node[1].kind == nnkIdent

func toSeq(node: NimNode): seq[string] {.compileTime.} =
  node.expectKind nnkPragma
  result = collect(for s in node: s.strVal)

template inheritanceClassInfo(
    result: ClassInfo;
    node: NimNode
) =
  if not node.isInheritance: error "Unsupported syntax", node
  if node[1].hasGenerics: error "Generics can be only in Normal classes for now", node[1]
  if node[2].kind != nnkPragmaExpr:
    # class A of B
    result.name = node[1]
    result.base = node[2]
    return
  # class A of B {.pragma.}
  if "open" in node[2][1]:
    warning "{.open.} is ignored in a definition of alias", node
  result.pragmas = node[2][1].toSeq()
  result.name = node[1]
  result.base = node[2][0]

proc getClassInfo*(head: NimNode): (ClassInfo, ClassKind) {.compileTime.} =
  case head.len
  of 0:
    # class A
    result[1] = ClassKind.Normal
    result[0].name = head
  of 1:
    error "Unsupported syntax", head
  of 2:
    result[0].isPub = head.isPub
    var node =
      if head.isPub: head[1]
      else: head
    case node.kind
    of nnkIdent:
      # class A
      result[1] = ClassKind.Normal
      result[0].name = node
    of nnkCall:
      if node[0].hasGenerics: error "Generics can be only in Normal classes for now", node
      result[0].name = node[0]
      if node.isDistinct:
        # class A(distinct B)
        result[1] = ClassKind.Distinct
        result[0].base = node[1][0]
        return
      # class A(B)
      result[1] = ClassKind.Alias
      result[0].base = node[1]
    of nnkInfix:
      result[1] = ClassKind.Inheritance
      result[0].inheritanceClassInfo(node)
    of nnkPragmaExpr:
      result[0].pragmas = node[1].toSeq()
      if node[0].isDistinct:
        # class A(distinct B) {.pragma.}
        result[1] = ClassKind.Distinct
        result[0].name = node[0][0]
        result[0].base = node[0][1][0]
        return
      if node[0].kind == nnkCall:
        # class A(B) {.pragma.}
        if "open" in node[1]:
          warning "{.open.} is ignored in a definition of alias", node
        result[1] = ClassKind.Alias
        result[0].name = node[0][0]
        result[0].base = node[0][1]
        return
      if node[0].hasGenerics:
        # class A[T, U] {.pragma.}
        result[0].name = node[0][0]
        result[0].generics = node[1..^1]
        return
      # class A {.pragma.}
      result[0].name = node[0]
    of nnkCommand:
      if node[0].hasGenerics: error "Generics can be only in Normal classes for now", node
      if node[1][0].eqIdent"impl":
        result[1] = ClassKind.Implementation
        result[0].name = node[0]
        if node[1][1].kind == nnkPragmaExpr:
          # class A impl IA {.pragma.}
          result[0].pragmas = node[1][1][1].toSeq()
          result[0].base = node[1][1][0]
          return
        # class A impl IA
        result[0].base = node[1][1]
        return
      error "Unsupported syntax", node
    of nnkBracketExpr:
      # class A[T, U]
      result[1] = ClassKind.Normal
      result[0].name = node[0]
      result[0].generics = node[1..^1]
    else:
      error "Unsupported syntax", node
  of 3:
    result[0].isPub = false
    result[1] = ClassKind.Inheritance
    result[0].inheritanceClassInfo(head)
  else:
    error "Too many arguments", head

proc distinguishClassKind*(head: NimNode): ClassKind {.compileTime.} =
  let node = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      head[1]
    else:
      head
  case node.len
  of 0:
    # class A
    return ClassKind.Normal
  of 1:
    error "Unsupported syntax", node
  of 2:
    case node.kind
    of nnkCall:
      if node.isDistinct:
        # class A(distinct B)
        return ClassKind.Distinct
      # class A(B)
      return ClassKind.Alias
    of nnkInfix:
      return ClassKind.Inheritance
    of nnkPragmaExpr:
      if node[0].isDistinct:
        # class A(distinct B) {.pragma.}
        return ClassKind.Distinct
      if node[0].kind == nnkCall:
        # class A(B) {.pragma.}
        return ClassKind.Alias
      if node[0].hasGenerics:
        # class A[T, U] {.pragma.}
        return ClassKind.Normal
      # class A {.pragma.}
      return ClassKind.Normal
    of nnkCommand:
      if node[1][0].eqIdent"impl":
        # class A impl IA
        return ClassKind.Implementation
      error "Unsupported syntax", node
    of nnkBracketExpr:
      # class A[T, U]
      return ClassKind.Normal
    else:
      error "Unsupported syntax", node
  of 3:
    return ClassKind.Inheritance
  else:
    error "Too many arguments", node
