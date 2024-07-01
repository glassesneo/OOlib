discard """
  action: "compile"
"""

import
  ../src/oolib

protocol Readable:
  var text: string

protocol Writable:
  var text: string
  proc `text=`(value: string)

protocol Product:
  var price: int

type Writer* {.protocoled.} = tuple
  write: proc(text: string)

class Book impl (Readable, Product):
  var
    text: string = ""
    price: int

class Diary impl (Readable, Writable, Product):
  var text {.initial.}: string = ""
  var price: int
  proc `text=`(value: string) =
    self.text = value

class HTMLWriter impl Writer:
  var writable: Writable
  proc write(text: string) =
    self.writable.text = text

let book = Book.new(price = 500)

let diary = Diary.new(price = 300)

var products: seq[Product] = @[]

products.add book.toProtocol().pick(Product)

products.add diary.toProtocol().pick(Product)

for product in products:
  echo product.price
