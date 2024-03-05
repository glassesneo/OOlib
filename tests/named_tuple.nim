discard """
  action: "compile"
"""

import
  ../src/oolib

class Person(tuple):
  var name: string
  var age: Natural
  proc greet =
    echo "Hello, I'm " & self.name & "."

let luigi: Person = ("Luigi", 26)

luigi.greet()
