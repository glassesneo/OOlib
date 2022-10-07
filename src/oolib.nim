import
  std/macros,
  oolib / [sub, classes, protocols],
  oolib / class_state / [states, context]

export
  optBase,
  pClass,
  pProtocol,
  ignored,
  initial

macro class*(head: untyped, body: untyped = newEmptyNode()): untyped =
  let
    (info, classKind) = getClassInfo(head)
    context = newContext(newState(info, classKind), body)
  result = newStmtList()
  result.add context.defClass()
  context.defBody(result)

proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)

proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`.
  T.isClass()

macro protocol*(head: untyped, body: untyped = newEmptyNode()): untyped =
  let
    info = parseProtocolHead(head)
    members = parseProtocolBody(body, info)
  result = defProtocol(info, members)

proc isProtocol*(T: typedesc): bool =
  ## Returns whether `T` is protocol or not.
  T.hasCustomPragma(pProtocol)

proc isProtocol*[T](instance: T): bool =
  ## Is an alias for `isProtocol(T)`.
  T.isProtocol()
