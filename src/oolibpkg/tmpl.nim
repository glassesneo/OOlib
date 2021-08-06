template defObj*(className, baseName) =
  type className {.final.} = ref object of baseName


template defObjPub*(className, baseName) =
  type className* {.final.} = ref object of baseName


template defDistinct*(className, baseName) =
  type className {.final.} = distinct baseName


template defDistinctPub*(className, baseName) =
  type className* {.final.} = distinct baseName


template asgnInNew*(name) =
  self.name = name
