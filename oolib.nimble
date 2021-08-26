# Package

version       = "0.2.2"
author        = "Glasses-Neo"
description   = "A nimble package which provides user-defined types, procedures, etc..."
license       = "WTFPL"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.8"

task tests, "Run all tests":
  exec "testament p 'tests/**.nim'"
