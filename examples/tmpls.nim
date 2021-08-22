import oolib


class A:
  var a: string

  template b*(c: string, d: typedesc, e: untyped) =
    proc `self.a c`: d =
      e
