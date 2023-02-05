discard """
  action: "run"
"""
import ../src/oolib

protocol Animal:
  var scientificName: string

  proc roar()
  func breathe()

  proc eat() = echo "eat!"

class pub Cat impl Animal:
  var scientificName*: string
  var name* {.ignored.}: string

  proc `new`(scientificName, name: string) =
    self.scientificName = scientificName
    self.name = name

  proc roar*() =
    echo "meow!"

  func breathe*() =
    discard

class Dog impl Animal:
  var scientificName: string
  var name {.ignored.}: string

  proc roar*() =
    echo "bark!"

  func breathe*() =
    discard

  proc walk() {.ignored.} =
    echo "walk!"

let cat = Cat.new("Felis catus", "Leo")
let dog = Dog.new("Canis lupus familiaris", "Wolf")

cat.roar()
cat.breathe()
dog.roar()
dog.breathe()
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
