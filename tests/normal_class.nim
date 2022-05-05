discard """
  action: "run"
"""
import ../src/oolib

class Sword:
  var offence: int

  proc attack() =
    echo "attack!"


class Gun:
  var
    capacity: uint
    bullets: uint
  proc `new`(capacity: uint) =
    self.capacity = capacity
    self.bullets = capacity

  proc shoot() =
    if self.bullets > 0:
      self.bullets = self.bullets - 1
    else:
      echo "Out of bullets!"


let sword = Sword.new(9)
let gun = Gun.new(6)

gun.shoot()
sword.attack()
gun.shoot()
