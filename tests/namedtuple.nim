import ../src/oolib

class Person(tuple):
  var name: string
  var age: int

let p: Person = ("John", 41)

echo p.name, p.age
