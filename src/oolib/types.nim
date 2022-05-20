import
  std/macros,
  std/sugar


type
  ClassKind* {.pure.} = enum
    Normal
    Inheritance
    Distinct
    Alias
    Implementation

  ClassInfo* = tuple
    isPub: bool
    pragmas: seq[string]
    generics: seq[NimNode]
    kind: ClassKind
    name, base: NimNode

  ClassMembers* = tuple
    body, ctorBase, ctorBase2: NimNode
    argsList, ignoredArgsList, constsList: seq[NimNode]


  ProtocolKind* {.pure.} = enum
    Normal

  ProtocolInfo* = tuple
    isPub: bool
    kind: ProtocolKind
    name: NimNode

  ProtocolMembers* = tuple
    argsList, procs, funcs: seq[NimNode]


proc nameWithGenerics*(info: ClassInfo): NimNode {.compileTime.} =
  ## Return `name[T, U]` if a class has generics.
  result = info.name
  if info.generics != @[]:
    result = nnkBracketExpr.newTree(
      result & info.generics
    )


func allArgsList*(members: ClassMembers): seq[NimNode] {.compileTime.} =
  members.argsList & members.ignoredArgsList


func withoutDefault*(argsList: seq[NimNode]): seq[NimNode] =
  result = collect:
    for v in argsList:
      v[^1] = newEmptyNode()
      v
