template defObj*(className) =
  type className = ref object


template defObjWithBase*(className, baseName) =
  type className = ref object of baseName


template defDistinct*(className, baseName) =
  type className {.final.} = distinct baseName


template defAlias*(className, baseName) =
  type className = baseName


template defProtocol*(protocolName) =
  type protocolName = tuple
