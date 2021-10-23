# 👑OOlib
![license](https://img.shields.io/github/license/Glasses-Neo/OOlib?color=blueviolet)
[![test](https://github.com/Glasses-Neo/OOlib/actions/workflows/test.yml/badge.svg)](https://github.com/Glasses-Neo/OOlib/actions/workflows/test.yml)
![contributors](https://img.shields.io/github/contributors/Glasses-Neo/OOlib?color=important)
![stars](https://img.shields.io/github/stars/Glasses-Neo/OOlib?style=social)

![icon](./oolib.png)

**OOlib is currently work in progress**🔥


## 🗺Overview
OOlib is a nimble package for object oriented programming.


## 📜Usage
```nim
import strformat
import oolib


# add `pub` prefix to export class
class pub Person:
  var
    name*: string
    age* = 0

  # auto insert `self` as first argument
  proc `$`*: string = fmt"<Person> name: {self.name}"

  proc happyBirthday* =
    inc self.age


# auto define constructor
let p1 = newPerson("Tony")
let p2 = newPerson("Steve", 100)
```


## ✨Features
- Member variables with default values
- Class data constants
- Definition of `proc`, `method`, `func`, etc... (the only exception being `macro`)
- Auto inserting `self` as first argument
- Auto definition of constructor (high performance!)
- Assistance with constructor definition
- `pub` modifier instead of `*`
- Inheritance with `of` modifier
- Creating distinct type with `distinct` modifier
- `{.final.}` by default
- `{.open.}` to allow inheritance
- `super` keyword for `method`
- Alias class

### 💭Planned
- `Pick` like TypeScript's `Pick`
- `let` member variables
- `struct`
- `protocol`


## Changelog
See [CHANGELOG](https://github.com/Glasses-Neo/OOlib/blob/develop/CHANGELOG.md)


## 🥷Author
[![Twitter](https://img.shields.io/twitter/follow/Glassesman10.svg?style=social&label=@Glassesman10)](https://twitter.com/Glassesman10)


## License
Copyright © 2021 Neo meganeo.programmer@gmail.com
This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
