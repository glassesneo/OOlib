discard """
  action: "run"
"""
import ../src/oolib

protocol Animal:
  var scientificName: string

  proc breathe()
  proc roar()

class Cat impl Animal:
  var scientificName: string
  var name {.ignored.}: string

  proc breathe() =
    echo "breathed!"

  proc roar() =
    echo "meow!"

class Dog impl Animal:
  var scientificName: string
  var name {.ignored.}: string

  proc breathe() =
    echo "breathed!"

  proc roar() =
    echo "bark!"

let cat = Cat.new("Felis catus", "Leo").toInterface()
let dog = Dog.new("Canis lupus familiaris", "Wolf").toInterface()

cat.breathe()
cat.roar()
dog.breathe()
dog.roar()
