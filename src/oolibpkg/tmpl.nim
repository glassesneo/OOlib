template defObj*(className) =
  type className = ref object


template defObjWithBase*(className, baseName) =
  type className = ref object of baseName


template defDistinct*(className, baseName) =
  type className {.final.} = distinct baseName


template asgnWith*(name) =
  self.name = name
