import
  std/macros,
  std/tables,
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
  let classBuilderKinds: Table[ClassKind, Builder] = {
    ClassKind.Normal: NormalBuilder.new().toInterface(),
    ClassKind.Inheritance: InheritanceBuilder.new().toInterface(),
    ClassKind.Distinct: DistinctBuilder.new().toInterface(),
    ClassKind.Alias: AliasBuilder.new().toInterface(),
    ClassKind.Implementation: ImplementationBuilder.new().toInterface()
  }.toTable()

  let
    classKind = distinguishClassKind(head)
    builder = classBuilderKinds[classKind]
    director = Director.new(builder = builder)

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
