# 👑OOlib
![icon](./oolib.png)

**OOlib is currently work in progress**🔥


## 🗺Overview
OOlib is a syntax sugar which provides user-defined types, procedures, etc...


## 📜Usage
```nim
import strformat
import oolib


# add `pub` prefix to publish class
class pub Person:
  var
    name*: string
    age*: int = 0

  # auto insert `self` as first argument
  proc `$`*: string = fmt"<Person> name: {self.name}"

  proc happyBirthday* =
    inc self.age


# auto define constructor
let p = newPerson("Tony")
```


## ✨Features
- Member variables with default values
- Definition of `proc`, `method`, `func`, etc... (the only exception being `macro`)
- Auto inserting `self` as first argument
- Auto definition of constructor (high performance!)
- Assistance with constructor definition
- `pub` modifier instead of `*`
- Inheritance with `of` modifier (for now, only object can be inherited)
- Creating distinct type with `distinct` modifier
- `{.final.}` by default
- `{.open.}` to allow inheritance

### 💭Planned
- Support for more modifiers (e.g. `[T]`, `{.pragma.}`)
- `let` member variables
- `super` keyword for `method`


## License
Copyright © 2021 Neo meganeo.programmer@gmail.com
This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
