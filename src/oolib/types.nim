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
