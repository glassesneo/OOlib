discard """
  action: "run"
"""
import ../src/oolib

protocol Animal:
  var scientificName: string

  proc breathe()
  proc roar()

class Cat impl Animal:
  var scientificName*: string
  var name* {.ignored.}: string

  proc breathe*() =
    echo "breathed!"

  proc roar*() =
    echo "meow!"

class Dog impl Animal:
  var scientificName: string
  var name {.ignored.}: string

  proc breathe*() =
    echo "breathed!"

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
