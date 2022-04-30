discard """
  action: "run"
"""
import ../src/oolib

class Animal {.open.}:
  var scientificName: string

  proc breathe() =
    echo "breathed!"

  method roar() {.base.} =
    echo "roared!"

class Cat of Animal:
  var name: string
  proc `new`(scientificName, name: string) =
    self.scientificName = scientificName
    self.name = name

  method roar() =
    echo "meow!"
    super.roar()

class Dog of Animal:
  var name: string
  proc `new`(scientificName, name: string) =
    self.scientificName = scientificName
    self.name = name

  method roar() =
    echo "bark!"
    super.roar()

let cat = Cat.new("Felis catus", "Leo")
let dog = Dog.new("Canis lupus familiaris", "Wolf")

cat.breathe()
cat.roar()
dog.breathe()
dog.roar()
