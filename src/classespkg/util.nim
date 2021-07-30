{.experimental: "strictFuncs".}
import macros

using
  node: NimNode

type
  ClassKind* = enum
    Normal
    Inheritance
    Distinct

  ClassStatus* = object
    isPub*: bool
    kind*: ClassKind
    name*, base*: NimNode


func newClassStatus(isPub = false; kind = Normal; name: NimNode;
    base = "RootObj".ident): ClassStatus =
  result = ClassStatus(
    isPub: isPub,
    kind: kind,
    name: name,
    base: base
  )

func isDistinct(node): bool =
  ## node.kind must be nnkCall
  result = node[1].kind == nnkDistinctTy


func isPub(node): bool =
  result =
    node.kind == nnkCommand and node[0].eqIdent"pub"


func isInheritance(node): bool =
  ## node.kind must be nnkInfix
  result = node[0].eqIdent"of"


func determineStatus(node; isPub: bool): ClassStatus =
  case node.kind
  of nnkIdent:
    result = newClassStatus(isPub = isPub, kind = Normal, name = node)
  of nnkCall:
    if node.isDistinct:
      return newClassStatus(isPub = isPub, kind = Distinct, name = node[
          0], base = node[1][0])
    error "not enough arguments in the bracket."
  of nnkInfix:
    if node.isInheritance:
      return newClassStatus(isPub = isPub, kind = Inheritance, name = node[
          1], base = node[2])
    error("cannot parse.", node)
  else:
    error("cannot parse.", node)


func parseClassName*(className: NimNode): ClassStatus =
  case className.len
  of 0:
    result = newClassStatus(name = className)
  of 1:
    error("not enough argument.", className)
  of 2:
    result = if className.isPub:
      determineStatus(className[1], className.isPub)
      else:
        determineStatus(className, className.isPub)
  of 3:
    if className.kind == nnkInfix and className.isInheritance:
      return newClassStatus(kind = Inheritance, name = className[1],
          base = className[2])
    error("cannot parse.", className)
  else:
    error("too many arguments", className)


template defObj*(className, baseName) =
  type className = ref object of baseName

template defObjPub*(className, baseName) =
  type className* = ref object of baseName

template defDistinct*(className, baseName) =
  type className = distinct baseName

template defDistinctPub*(className, baseName) =
  type className* = distinct baseName
