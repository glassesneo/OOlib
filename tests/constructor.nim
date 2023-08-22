discard """
  action: "compile"
"""

import
  ../src/oolib

class Gun:
  var
    offence: int
    capacity = 6
    price: int

  proc `new`(offence: int) =
    self.offence = offence
    self.capacity = 8
    self.price = 300

  proc `new`(capacity: int) =
    self.offence = 14
    self.capacity = capacity
    self.price = 200

# This `new()` is made from type signature
let _ = Gun.new(offence = 5, price = 6)

# 2nd one
let _ = Gun.new(offence = 12)

# 3rd one
let _ = Gun.new(capacity = 10)

class Sword:
  var
    offence: int
    price {.initial.} = 100

# made from type signature
let _ = Sword.new(8)
