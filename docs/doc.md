> [!WARNING]
> Since OOlib is currently work in progress, the features may change easily.

# class
Generates a `ref object`.
Generics and inheritance are not supported.

```nim
class pub Color:
  var colorCode: string

  proc rgb: tuple[red, green, blue: range[0..225]] =
    ...
```

## export marker
Unlike other identifiers, the name of `class` cannot be modified with `*` to export. Use `pub` keyword instead.
```nim
class pub Color:
  var colorCode: string
```

## member variable
Only the `var` statement is supported. It can have a default value.

```nim
class Square:
  var width, height: int = 5
  var color: Color
```

## routines
`class` can have the all routines in Nim, excluding `macro`. The special keyword `self`, an identifier to represent the instance of a type, is automatically inserted as a first argument of a routine.

```nim
class Square:
  var width, height: int
  var color: string

  proc echoInfo =
    ...

  func area: int =
    return self.width * self.height
```

## constructor
### automatic definition
`class` reads its variable signatures and make them into its constructor's argument. If there are default values in the signatures, they are also applied to the constructor's arguments.

```nim
class Square:
  var
    width: int
    height: int
    color: string = "#0000ff"

  # a constructor with the arguments above is automatically defined

let square1 = Square.new(5, 7)
let square2 = Square.new(7, 6, "#ffffff")
```

### {.initial.} pragma
You can declare a variable that has an initial value by `{.initial.}`. Unlike the default value, an initial value has nothing to do with the constructor and an initial value is absolutely substituted for its variable.
```nim
class Square:
  var width: int
  var height {.initial.} = 5
  var color = "#0000ff"

let square1 = Square.new(5, "#000000")
let square2 = Square.new(7, 6, "#ffffff") # not compiled
```

### manual definition
There is a way to define a constructor manually. The constructor in `class` is represented as `new`. It can be defined like a normal procedure and is similar to `__init__` in Python.

```nim
class Square:
  var width, height: int
  var color: string

  proc `new`(length: int, color: string) =
    self.width = length
    self.height = length
    self.color = color
```

You can define constructors as many as you want. In the example below, 3 constructors are defined for `Square` type, including the one automatically generated.

```nim
class Square:
  var width: int
  var height: int
  var color: string = "#0000ff"

  proc `new`(length: int, color: string) =
    self.width = length
    self.height = length
    self.color = color

  proc `new`(width, height: int, rgb: (int, int, int)) =
    self.width = width
    self.height = height
    ...
```

## distinct class
`class` can also handle `distinct` type. It's easy to read and write.
```nim
class Dollar(distinct int):
  proc `+`(other: Dollar): Dollar {.borrow.}
  proc `-`(other: Dollar): Dollar {.borrow.}

  proc `*`(n: Natural): Dollar = Dollar(self.int * n)
  proc `/`(n: Natural): Dollar = Dollar(self.int / n)

var myMoney = 12.Dollar
```

## named tuple class
You can define named tuple as well.
```nim
class Person(tuple):
  var name: string
  var age: Natural
  proc greet =
    echo "Hello, I'm " & self.name & "."

let luigi: Person = ("Luigi", 26)

luigi.greet()
```

# protocol and implementation
The role of `protocol` is to provide the features of interface in other languages. `class` can implement `protocol`.

## protocol attributes
`protocol` can only have variables and procedures. The default value and default implementation are not supported.
```nim
protocol AnimalBehavior:
  var name: string

  proc eat(something: string)
  proc move
```

## implementation class
`class` can implement `protocol` via `impl` keyword. `class` must define the implementation of each attribute defined in `protocol`.
```nim
class Dog impl AnimalBehavior:
  var name: string

  proc eat(something: string) =
    echo "eating", " ", something, "!"

  proc move =
    echo "moving!"

  proc bark =
    echo "bark!"
```

### multiple implementation
Multiple implementation is supported. The attributes all the protocols have must be defined in `class`.
```nim
protocol CanFly:
  proc fly

class Bird impl (AnimalBehavior, CanFly):
  var name: string

  proc eat(something: string) =
    echo "eating ", something, "!"

  proc move =
    echo "moving!"

  proc fly =
    echo "flying!"
```

### overloading
Thanks to Nim's procedure overloading, no error occurs when the multiple procedures with the same name are defined, provided their signatures aren't same.
```nim
protocol PFoo:
  proc doSomething(x: string)

protocol PBar:
  proc doSomething(x: int)

class FooBar impl (PFoo, PBar):
  # implements PFoo's procedure
  proc doSomething(x: string) =
    echo "do something"

  # implements PBar's procedure
  proc doSomething(x: int) =
    echo "do something"

  # defines its own procedure
  proc doSomething(x: bool) =
    echo "do something"
```

### converting `class` to protocol tuple
when you use `protocol` and call a function that requires its type, you must call `toProtocol()`.
```nim
class Cat impl AnimalBehavior:
  proc eat(something: string) =
    echo "eating", " ", something, "!"

  proc move =
    echo "moving!"

  proc meow =
    echo "meow!"

class Registry:
  proc registerAnimal(registry: Registry, animal: AnimalBehavior) =
    ...

let registry = Registry.new()

let
  dog = Dog.new("dog")
  cat = Cat.new("cat")


var animals: seq[AnimalBehavior] = @[]
animals.add dog.toProtocol()
animals.add cat.toProtocol()

for animal in animals:
  registry.registerAnimal(animal)
```
