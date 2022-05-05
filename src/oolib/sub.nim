import
  std/macros


template pClass* {.pragma.}
  ## Is used as pragma.


template pProtocol* {.pragma.}
  ## Is used as pragma.


template ignored* {.pragma.}
  ## Is used as pragma.


macro optBase*(p: untyped): untyped =
  ## Decides whether to include {.base.} or not for use in auto generated methods
  let
    unbased = p.copyNimTree
    compileStmt = p.copyNimTree
  compileStmt[4] = nnkPragma.newTree(ident"base")

  result = p
  result[4] = nnkPragma.newTree(ident"base")
  result = quote do:
    {.warningAsError[UseBase]: on.}
    when compiles(`compileStmt`):
      `result`
    else:
      `unbased`

    {.warningAsError[UseBase]: off.}
