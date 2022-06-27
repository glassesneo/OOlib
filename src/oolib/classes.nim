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
  result.kind = Inheritance
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

proc getClassInfo*(head: NimNode): ClassInfo {.compileTime.} =
  case head.len
  of 0:
    # class A
    result.kind = ClassKind.Normal
    result.name = head
  of 1:
    error "Unsupported syntax", head
  of 2:
    result.isPub = head.isPub
    var node =
      if head.isPub: head[1]
      else: head
    case node.kind
    of nnkIdent:
      # class A
      result.kind = ClassKind.Normal
      result.name = node
    of nnkCall:
      if node[0].hasGenerics: error "Generics can be only in Normal classes for now", node
      result.name = node[0]
      if node.isDistinct:
        # class A(distinct B)
        result.kind = Distinct
        result.base = node[1][0]
        return
      # class A(B)
      result.kind = Alias
      result.base = node[1]
    of nnkInfix:
      result.inheritanceClassInfo(node)
    of nnkPragmaExpr:
      result.pragmas = node[1].toSeq()
      if node[0].isDistinct:
        # class A(distinct B) {.pragma.}
        result.kind = Distinct
        result.name = node[0][0]
        result.base = node[0][1][0]
        return
      if node[0].kind == nnkCall:
        # class A(B) {.pragma.}
        if "open" in node[1]:
          warning "{.open.} is ignored in a definition of alias", node
        result.kind = Alias
        result.name = node[0][0]
        result.base = node[0][1]
        return
      if node[0].hasGenerics:
        # class A[T, U] {.pragma.}
        result.name = node[0][0]
        result.generics = node[1..^1]
        return
      # class A {.pragma.}
      result.name = node[0]
    of nnkCommand:
      if node[0].hasGenerics: error "Generics can be only in Normal classes for now", node
      if node[1][0].eqIdent"impl":
        result.kind = Implementation
        result.name = node[0]
        if node[1][1].kind == nnkPragmaExpr:
          # class A impl IA {.pragma.}
          result.pragmas = node[1][1][1].toSeq()
          result.base = node[1][1][0]
          return
        # class A impl IA
        result.base = node[1][1]
        return
      error "Unsupported syntax", node
    of nnkBracketExpr:
      # class A[T, U]
      result.kind = ClassKind.Normal
      result.name = node[0]
      result.generics = node[1..^1]
    else:
      error "Unsupported syntax", node
  of 3:
    result.isPub = false
    result.inheritanceClassInfo(head)
  else:
    error "Too many arguments", head
