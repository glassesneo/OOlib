discard """
  action: "run"
"""

import
  std/unittest,
  ../src/oolib

protocol Animal:
  proc breathe()

protocol Dancable:
  proc dance()

protocol Unrelated:
  proc unrelated()

class Dog impl Animal:
  var name: string
  proc breathe = discard

class Human impl (Animal, Dancable):
  var name: string
  proc breathe = discard
  proc dance = discard

class Robot impl Dancable:
  proc dance = discard

let doggo = Dog.new("Doggo")
let man = Human.new("Man")
let robot = Robot.new()

check doggo.isInstanceOf Animal
check doggo.isInstanceOf Dog

check not doggo.isInstanceOf Human
check not doggo.isInstanceOf Unrelated
check not man.isInstanceOf Unrelated

check man.isInstanceOf Animal
check man.isInstanceOf Dancable
check man.isInstanceOf Human
