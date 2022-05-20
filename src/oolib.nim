import
  std/macros,
  oolib / [sub, types, classes, protocols],
  oolib / state / [states, context]

export
  optBase,
  pClass,
  pProtocol,
  ignored


macro class*(
    head: untyped,
    body: untyped = nnkEmpty.newNimNode
): untyped =
  let
    info = getClassInfo(head)
    context = newContext(newState(info))
    members = context.getClassMembers(body, info)
    theClass = newStmtList()
  context.defClass(theClass, info)
  theClass.add members.body.copy()
  context.defConstructor(theClass, info, members)
  context.defMemberVars(theClass, members)
  context.defMemberRoutines(theClass, info, members)
  result = theClass
  echo result.repr


proc isClass*(T: typedesc): bool =
  ## Returns whether `T` is class or not.
  T.hasCustomPragma(pClass)


proc isClass*[T](instance: T): bool =
  ## Is an alias for `isClass(T)`.
  T.isClass()


macro protocol*(head: untyped, body: untyped = newEmptyNode()): untyped =
  let
    info = parseProtocolHead(head)
    members = parseProtocolBody(body)
  result = defProtocol(info, members)


proc isProtocol*(T: typedesc): bool =
  ## Returns whether `T` is protocol or not.
  T.hasCustomPragma(pProtocol)


proc isProtocol*[T](instance: T): bool =
  ## Is an alias for `isProtocol(T)`.
  T.isProtocol()
