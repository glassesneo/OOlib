import oolib


class A:
  # Constructor of `A` is defined automatically
  var
    a: int
    b: string

class B:
  var
    a: int
    b: string
  # If `new` is defined, constructor won't be defined automatically
  proc `new`(c: string) =
    self.a = c.len
    self.b = c

class C:
  # Constructor of `D` is defined automatically in the same as `A`
  # If variables have default values, they will be refected in the constructor arguments
  # Even in this case, types have to be explicit
  var
    a: int = 0
    b: string

class D:
  var
    a: int = 0
    b: string
  # In this case, variables that have default values is automatically inserted in constructor arguments and constructor will be inserted with `self.a = a` at the beginning of its body
  proc `new`(c, d: string) =
    self.b = c&d[^1..0]


let
  a* = newA(1, "auto")
  b* = newB("myself")
  c1* = newC(1, "default and auto")
  c2* = newC(b = "default and auto")
  d1* = newD(1, "default and", "myself")
  d2* = newD(c = "default and", d = "myself")
