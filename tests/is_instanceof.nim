discard """
  action: "compile"
"""

import
  std/unittest,
  ../src/oolib

protocol Readable:
  var text: string

class Book impl Readable:
  var title: string
  var text: string = ""

class Human:
  var name: string

let
  book = Book.new(title = "Autobiography")
  me = Human.new("Me")

check book.isInstanceOf(Readable)
check book.isInstanceOf(Book)
check me.isInstanceOf(Human)

check not me.isInstanceOf(Readable)
check not book.isInstanceOf(Human)
