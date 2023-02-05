import
  std/macros,
  ./types

func isDistinct(node: NimNode): bool {.compileTime.} =
  node.kind == nnkCall and node[1].kind == nnkDistinctTy

proc distinguishClassKind*(head: NimNode): ClassKind {.compileTime.} =
  let node = block:
    if head.kind == nnkCommand and head[0].eqIdent"pub":
      head[1]
    else:
      head
  case node.len
  # class A
  of 0: return ClassKind.Normal

  of 1: error "Unsupported syntax", node
  of 2:
    case node.kind
    of nnkCall:
      # class A(distinct B)
      if node.isDistinct: return ClassKind.Distinct
      # class A(B)
      return ClassKind.Alias
    of nnkInfix: return ClassKind.Inheritance

    of nnkPragmaExpr:
      # class A(distinct B) {.pragma.}
      if node[0].isDistinct: return ClassKind.Distinct
      # class A(B) {.pragma.}
      if node[0].kind == nnkCall: return ClassKind.Alias
      # class A {.pragma.}
      return ClassKind.Normal

    of nnkCommand:
      # class A impl IA
      if node[1][0].eqIdent"impl": return ClassKind.Implementation
      error "Unsupported syntax", node
    # class A[T, U]
    of nnkBracketExpr: return ClassKind.Normal
    else: error "Unsupported syntax", node

  of 3: return ClassKind.Inheritance
  else: error "Too many arguments", node
