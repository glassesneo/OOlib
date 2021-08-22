import oolib


class A {.open.}:
  method a {.base.} =
    echo "abstract!"

class B of A:
  method a =
    super.a()
    echo "concrete!"
