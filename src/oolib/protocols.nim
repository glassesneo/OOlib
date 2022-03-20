import macros
import util, tmpl


type
  ProtocolKind* = enum
    Normal

  ProtocolInfo* = tuple
    isPub: bool
    kind: ProtocolKind
    name: NimNode

  ProtocolMembers* = tuple
    argsList, procs, funcs: seq[NimNode]


proc newProtocolInfo(
    isPub = false,
    kind = ProtocolKind.Normal,
    name: NimNode
): ProtocolInfo =
  (
    isPub: isPub,
    kind: kind,
    name: name
  )


proc parseProtocolHead*(head: NimNode): ProtocolInfo =
  case head.len:
  of 0:
    result = newProtocolInfo(name = head)
  of 1:
    error "Unsupported syntax", head
  of 2:
    result = newProtocolInfo(
      isPub = head[0].isPub,
      name = head[1]
    )
  else:
    error "Unsupported syntax", head


proc parseProtocolBody*(body: NimNode): ProtocolMembers =
  for node in body:
    case node.kind
    of nnkVarSection:
      for n in node:
        result.argsList.add n
    of nnkProcDef:
      result.procs.add node
    of nnkFuncDef:
      result.funcs.add node
    else:
      error "Unsupported syntax", node


func toTupleMemberProc(node: NimNode): NimNode =
  newIdentDefs node.name, nnkProcTy.newTree(node.params, node[4])


func toTupleMemberFunc(node: NimNode): NimNode =
  newIdentDefs node.name, nnkProcTy.newTree(
    node.params,
    if node[4].kind == nnkEmpty:
      newEmptyNode()
    else:
      node[4].add ident"noSideEffect"
  )


proc defProtocol*(info: ProtocolInfo, members: ProtocolMembers): NimNode =
  result = newStmtList getAst defProtocol(info.name)
  if info.isPub:
    result[0][0][0] = newPostfix(result[0][0])
  for v in members.argsList:
    result[0][0][2].add v
  for p in members.procs:
    result[0][0][2].add p.toTupleMemberProc()
  for f in members.funcs:
    result[0][0][2].add f.toTupleMemberFunc()
