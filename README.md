# 👑OOlib
![license](https://img.shields.io/github/license/glassesneo/OOlib?color=blueviolet)
[![test](https://github.com/glassesneo/OOlib/actions/workflows/test.yml/badge.svg)](https://github.com/glassesneo/OOlib/actions/workflows/test.yml)
![contributors](https://img.shields.io/github/contributors/glassesneo/OOlib?color=important)
![stars](https://img.shields.io/github/stars/glassesneo/OOlib?style=social)

**OOlib is currently work in progress**🔥

## 🗺Overview
OOlib is a nimble package for object oriented programming.

## 📜Usage
### class
```nim
import oolib

class Person:
  var
    name: string
    age = 0

  proc greet =
    echo "hello, I'm ", self.name

let steve = Person.new(name = "Steve")
let tony = Person.new(name = "Tony", age = 30)

steve.greet()
tony.greet()
```

### protocol
```nim
import oolib

protocol Readable:
  var text: string

protocol Writable:
  var text: string
  proc `text=`(value: string)

protocol Product:
  var price: int

protocol pub Writer:
  proc write(text: string)

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
```

See [doc.md](https://github.com/glassesneo/OOlib/blob/develop/docs/doc.md) for more details

## ✨Features
- `class`
    - Automatic generation of constructor
    - `self` inserted in procedures
    - All routines (e.g., method, converter, template) are supported, excluding macro
- `protocol`
    - A Kotlin-like interface
    - Defining setter/getter
- `construct`
    - An easy way to declare a class without `class`, only supporting normal class
- `protocoled`
    - The same as `construct`, but for interface
- `isInstanceOf` for checking if a variable is an instance of a class or can be converted into a protocol

## 💭Planning
- `struct` from Swift
- `dataclass` from Kotlin
- `sealed class` from Kotlin

## Changelog
See [CHANGELOG](https://github.com/glassesneo/OOlib/blob/develop/CHANGELOG.md)

## License
Copyright © 2024 Neo glassesneo@protonmail.com
This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
