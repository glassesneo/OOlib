template defObj*(className, baseName) =
  type className {.final.} = ref object of baseName


template defDistinct*(className, baseName) =
  type className {.final.} = distinct baseName


template asgnWith*(name) =
  self.name = name
