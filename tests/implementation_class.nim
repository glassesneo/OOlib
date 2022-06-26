discard """
  action: "run"
"""
import ../src/oolib

protocol Animal:
  var scientificName: string

  func breathe()
  proc roar()

  proc eat() = echo "eat!"

class pub Cat impl Animal:
  var scientificName*: string
  var name* {.ignored.}: string

  proc `new`(scientificName; name) =
    self.scientificName = scientificName
    self.name = name

  func breathe*() =
    # echo "breathed!"
    discard

  proc roar*() =
    echo "meow!"

class Dog impl Animal:
  var scientificName: string
  var name {.ignored.}: string

  func breathe*() =
    # echo "breathed!"
    discard

  proc roar*() =
    echo "bark!"

  proc walk() {.ignored.} =
    echo "walk!"

let cat = Cat.new("Felis catus", "Leo")
let dog = Dog.new("Canis lupus familiaris", "Wolf")

cat.breathe()
cat.roar()
dog.breathe()
dog.roar()
dog.walk()

proc echoName(animals: seq[Animal]) =
  for a in animals:
    echo a.scientificName

let animals = @[
  cat.toInterface(),
  dog.toInterface()
]

echoName(animals)
animals[0].eat()
