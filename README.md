# 👑classes
**classes is currently work in progress**🔥


## 🗺Overview
classes is a syntax sugar which provides user-defined types, procedures, etc...


## 📜Usage
```nim
import strformat
import classes


# add `pub` prefix to publish class
class pub Person:
  var
    name*: string
    age: int
    height, weight: float

  # automatically insert `self` as first argument
  proc happyBirthday =
    inc self.age

  method greeting {.base.} =
    echo fmt"Hello, I'm {self.name}."

  # support for `template`
  template p =
    # do something


class BusinessPerson of Person:
  var workspace: string

  method greeting =
    echo fmt"Hello, I'm {self.name} from {self.workspace} Inc."
```


## ✨Features
- Can parse some modifiers. (e.g. `pub`, `of`, `distinct`)
- Support for `proc`, `method`, `func`, `iterator`, `template`.
- Can inherit an object.
- Automatically insert `self` as first argument.

### 💭Planned
- Support for more modifiers. (e.g. `[T]`, `{.pragma.}`, `ref`)
- Define `let` variables.
- Provide `super` keyword for `method`.
- Define constructor easily.


## License
Copyright © 2021 Neo meganeo.programmer@gmail.com
This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
