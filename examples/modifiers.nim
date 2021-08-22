import oolib


# Ordinal class
class A:
  discard

# Exported class
class pub B:
  discard

# Super class
# In order to allow inheritance, must add {.open.}
class C {.open.}:
  discard

# Sub class
class D of C:
  discard

# Distinct class
class E(distinct A):
  discard
