discard """
  action: "run"
"""
import ../src/oolib

class Yen(distinct int):
  proc `+`(v: Yen): Yen {.borrow.}
  proc `$`: string {.borrow.}

echo 100.Yen + 50.Yen
