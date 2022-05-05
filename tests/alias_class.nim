discard """
  action: "run"
"""
import ../src/oolib

class Item(string)

class Items(seq[Item])

let items: Items = @[
  "apple",
  "orange",
  "peach"
]

for fruit in items:
  echo fruit
