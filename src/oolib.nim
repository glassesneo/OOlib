import
  std/macros,
  oolib/[sub, classes, protocols, types],
  oolib/class_builder/[
    builder,
    normal_builder,
    inheritance_builder,
    distinct_builder,
    alias_builder,
    implementation_builder
  ]

export
  optBase,
  pClass,
  pProtocol,
  ignored,
  initial

macro class*(head: untyped, body: untyped = newEmptyNode()): untyped =
  let classKind = distinguishClassKind(head)

  case classKind
  of ClassKind.Normal:
    let builder = NormalBuilder.new().toInterface()
    let director = Director.new(builder = builder)
    result = director.build(head, body)

  of ClassKind.Inheritance:
    let builder = InheritanceBuilder.new().toInterface()
    let director = Director.new(builder = builder)
    result = director.build(head, body)

  of ClassKind.Distinct:
    let builder = DistinctBuilder.new().toInterface()
    let director = Director.new(builder = builder)
    result = director.build(head, body)

  of ClassKind.Alias:
    let builder = AliasBuilder.new().toInterface()
    let director = Director.new(builder = builder)
    result = director.build(head, body)

  of ClassKind.Implementation:
    let builder = ImplementationBuilder.new().toInterface()
    let director = Director.new(builder = builder)
    result = director.build(head, body)

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
