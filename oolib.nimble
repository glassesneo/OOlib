# Package

version       = "0.3.0"
author        = "Glasses-Neo"
description   = "A nimble package which provides user-defined types, procedures, etc..."
license       = "WTFPL"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.8"

task tests, "Run all tests":
  exec "testament p 'tests/**.nim'"

task show, "Show testresults":
  exec "testament html"
  exec "open testresults.html"
