
import std/hashes
import std/tables
import system/exceptions

type
  HMTNode60_63[T, U] = object
    children: array[16, seq[(T, U)]] #to handle collisions
  HMTNode55_59[T, U] = object
    children: array[32, ref HMTNode60_63[T, U]]
  HMTNode50_54[T, U] = object
    children: array[32, ref HMTNode55_59[T, U]]
  HMTNode45_49[T, U] = object
    children: array[32, ref HMTNode50_54[T, U]]
  HMTNode40_44[T, U] = object
    children: array[32, ref HMTNode45_49[T, U]]
  HMTNode35_39[T, U] = object
    children: array[32, ref HMTNode40_44[T, U]]
  HMTNode30_34[T, U] = object
    children: array[32, ref HMTNode35_39[T, U]]
  HMTNode25_29[T, U] = object
    children: array[32, ref HMTNode30_34[T, U]]
  HMTNode20_24[T, U] = object
    children: array[32, ref HMTNode25_29[T, U]]
  HMTNode15_19[T, U] = object
    children: array[32, ref HMTNode20_24[T, U]]
  HMTNode10_14[T, U] = object
    children: array[32, ref HMTNode15_19[T, U]]
  HMTNode5_9[T, U] = object
    children: array[32, ref HMTNode10_14[T, U]]
  HMTNode0_4[T, U] = object
    children: array[32, ref HMTNode5_9[T, U]]
#  HMTNode[T, U] = concept n
#    HMTNode0_4[T, U] |
#    HMTNode5_9[T, U] |
#    HMTNode10_14[T, U] |
#    HMTNode15_19[T, U] |
#    HMTNode20_24[T, U] |
#    HMTNode25_29[T, U] |
#    HMTNode30_34[T, U] |
#    HMTNode35_39[T, U] |
#    HMTNode40_44[T, U] |
#    HMTNode45_49[T, U] |
#    HMTNode50_54[T, U] |
#    HMTNode55_59[T, U] |
#    HMTNode60_63[T, U]
#  NonLeafHMTNode[T, U] =
#    HMTNode0_4[T, U] |
#    HMTNode5_9[T, U] |
#    HMTNode10_14[T, U] |
#    HMTNode15_19[T, U] |
#    HMTNode20_24[T, U] |
#    HMTNode25_29[T, U] |
#    HMTNode30_34[T, U] |
#    HMTNode35_39[T, U] |
#    HMTNode40_44[T, U] |
#    HMTNode45_49[T, U] |
#    HMTNode50_54[T, U] |
#    HMTNode55_59[T, U]
  HMT*[T, U] = object
    ## Top-level HMT container storing the root node.
    ##
    ## Parameters
    ## - `T`: key type
    ## - `U`: value type
    data: HMTNode0_4[T, U]
    len: uint64

func initHMT*[T, U](): HMT[T, U] = HMT[T, U](data: HMTNode0_4[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]), len: 0)

func hashHMT[T](a: T): uint64 = uint64(hash(a))

func presentMap(a: uint64): array[13, int] =
  return [
    int((a shr 59) and 0b11111),
    int((a shr 54) and 0b11111),
    int((a shr 49) and 0b11111),
    int((a shr 44) and 0b11111),
    int((a shr 39) and 0b11111),
    int((a shr 34) and 0b11111),
    int((a shr 29) and 0b11111),
    int((a shr 24) and 0b11111),
    int((a shr 19) and 0b11111),
    int((a shr 14) and 0b11111),
    int((a shr 09) and 0b11111),
    int((a shr 04) and 0b11111),
    int((a shr 00) and 0b01111)
  ]

func `[]`*[T, U](a: HMT[T, U], key: T): U =
  ## Retrieve the value associated with `key`.
  ##
  ## Behaviour on missing keys should match `std/tables`'s `[]`
  ## operator (implementation-defined here).
  var
    keyhash = hashHMT(key)
    map = presentMap(keyhash)
  let node1 = a.data
  if node1.children[map[0]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node2 = node1.children[map[0]][]
  if node2.children[map[1]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node3 = node2.children[map[1]][]
  if node3.children[map[2]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node4 = node3.children[map[2]][]
  if node4.children[map[3]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node5 = node4.children[map[3]][]
  if node5.children[map[4]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node6 = node5.children[map[4]][]
  if node6.children[map[5]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node7 = node6.children[map[5]][]
  if node7.children[map[6]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node8 = node7.children[map[6]][]
  if node8.children[map[7]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node9 = node8.children[map[7]][]
  if node9.children[map[8]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node10 = node9.children[map[8]][]
  if node10.children[map[9]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node11 = node10.children[map[9]][]
  if node11.children[map[10]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node12 = node11.children[map[10]][]
  if node12.children[map[11]] == nil: raise newException(KeyError, "key " & $key & " not found in HMT")
  let node13 = node12.children[map[11]][]
  for i in node13.children[map[12]]:
    if i[0] == key: return i[1]
  raise newException(KeyError, "key " & $key & " not found in HMT")

func getOrDefault*[T, U](a: HMT[T, U], key: T, default: U): U =
  ## Get the value for `key`, or `default` if `key` is not present.
  try: return a[key]
  except KeyError: return default

func insert*[T, U](a: HMT[T, U], key: T, value: U): HMT[T, U] =
  ## Insert or replace `key` with `value`, returning the updated HMT.
  ##
  ## The implementation may preserve structural sharing where
  ## possible.
  var
    keyhash = hashHMT(key)
    map = presentMap(keyhash)
  let node1 = a.data
  let node2 = if node1.children[map[0]] == nil: HMTNode5_9[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node1.children[map[0]][]
  let node3 = if node2.children[map[1]] == nil: HMTNode10_14[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node2.children[map[1]][]
  let node4 = if node3.children[map[2]] == nil: HMTNode15_19[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node3.children[map[2]][]
  let node5 = if node4.children[map[3]] == nil: HMTNode20_24[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node4.children[map[3]][]
  let node6 = if node5.children[map[4]] == nil: HMTNode25_29[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node5.children[map[4]][]
  let node7 = if node6.children[map[5]] == nil: HMTNode30_34[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node6.children[map[5]][]
  let node8 = if node7.children[map[6]] == nil: HMTNode35_39[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node7.children[map[6]][]
  let node9 = if node8.children[map[7]] == nil: HMTNode40_44[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node8.children[map[7]][]
  let node10 = if node9.children[map[8]] == nil: HMTNode45_49[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node9.children[map[8]][]
  let node11 = if node10.children[map[9]] == nil: HMTNode50_54[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node10.children[map[9]][]
  let node12 = if node11.children[map[10]] == nil: HMTNode55_59[T, U](children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]) else: node11.children[map[10]][]
  let node13 = if node12.children[map[11]] == nil: HMTNode60_63[T, U](children: [@[], @[], @[], @[], @[], @[], @[], @[], @[], @[], @[], @[], @[], @[], @[], @[]]) else: node12.children[map[11]][]
  var node13a = new HMTNode60_63[T, U]
  var replaced: uint64 = 1
  for i in 0..<16:
    node13a[].children[i] = @[]
    for j in 0..node13.children[i].high:
      if node13.children[i][j][0] != key: node13a[].children[i].add(node13.children[i][j])
      else: replaced = 0
    if i == map[12]: node13a[].children[i].add((key, value))
  var node12a = new HMTNode55_59[T, U]
  for i in 0..<32:
    if i == map[11]: node12a[].children[i] = node13a
    else: node12a[].children[i] = node12.children[i]
  var node11a = new HMTNode50_54[T, U]
  for i in 0..<32:
    if i == map[10]: node11a[].children[i] = node12a
    else: node11a[].children[i] = node11.children[i]
  var node10a = new HMTNode45_49[T, U]
  for i in 0..<32:
    if i == map[9]: node10a[].children[i] = node11a
    else: node10a[].children[i] = node10.children[i]
  var node9a = new HMTNode40_44[T, U]
  for i in 0..<32:
    if i == map[8]: node9a[].children[i] = node10a
    else: node9a[].children[i] = node9.children[i]
  var node8a = new HMTNode35_39[T, U]
  for i in 0..<32:
    if i == map[7]: node8a[].children[i] = node9a
    else: node8a[].children[i] = node8.children[i]
  var node7a = new HMTNode30_34[T, U]
  for i in 0..<32:
    if i == map[6]: node7a[].children[i] = node8a
    else: node7a[].children[i] = node7.children[i]
  var node6a = new HMTNode25_29[T, U]
  for i in 0..<32:
    if i == map[5]: node6a[].children[i] = node7a
    else: node6a[].children[i] = node6.children[i]
  var node5a = new HMTNode20_24[T, U]
  for i in 0..<32:
    if i == map[4]: node5a[].children[i] = node6a
    else: node5a[].children[i] = node5.children[i]
  var node4a = new HMTNode15_19[T, U]
  for i in 0..<32:
    if i == map[3]: node4a[].children[i] = node5a
    else: node4a[].children[i] = node4.children[i]
  var node3a = new HMTNode10_14[T, U]
  for i in 0..<32:
    if i == map[2]: node3a[].children[i] = node4a
    else: node3a[].children[i] = node3.children[i]
  var node2a = new HMTNode5_9[T, U]
  for i in 0..<32:
    if i == map[1]: node2a[].children[i] = node3a
    else: node2a[].children[i] = node2.children[i]
  var node1a = new HMTNode0_4[T, U]
  node1a[].children = node1.children
  for i in 0..<32:
    if i == map[0]: node1a[].children[i] = node2a
    else: node1a[].children[i] = node1.children[i]
  return HMT[T, U](data: node1a[], len: a.len+replaced)

func del*[T, U](a: HMT[T, U], key: T): HMT[T, U] =
  ## Delete `key` from the HMT and return the resulting HMT.
  ## If `key` is not present the original HMT should be returned
  ## unchanged.
  var
    keyhash = hashHMT(key)
    map = presentMap(keyhash)
  let node1 = a.data
  if node1.children[map[0]] == nil: return a
  let node2 = node1.children[map[0]][]
  if node2.children[map[1]] == nil: return a
  let node3 = node2.children[map[1]][]
  if node3.children[map[2]] == nil: return a
  let node4 = node3.children[map[2]][]
  if node4.children[map[3]] == nil: return a
  let node5 = node4.children[map[3]][]
  if node5.children[map[4]] == nil: return a
  let node6 = node5.children[map[4]][]
  if node6.children[map[5]] == nil: return a
  let node7 = node6.children[map[5]][]
  if node7.children[map[6]] == nil: return a
  let node8 = node7.children[map[6]][]
  if node8.children[map[7]] == nil: return a
  let node9 = node8.children[map[7]][]
  if node9.children[map[8]] == nil: return a
  let node10 = node9.children[map[8]][]
  if node10.children[map[9]] == nil: return a
  let node11 = node10.children[map[9]][]
  if node11.children[map[10]] == nil: return a
  let node12 = node11.children[map[10]][]
  if node12.children[map[11]] == nil: return a
  let node13 = node12.children[map[11]][]
  for i in node13.children[map[12]]:
    if i[0] == key:
      var node13a = new HMTNode60_63[T, U]
      func isnil[T, U](arr: array[16, seq[(T, U)]]): bool =
        for i in arr:
          if i.len() > 0: return false
        return true
      for i in 0..<16:
        node13a[].children[i] = @[]
        for j in 0..node13.children[i].high:
          if node13.children[i][j][0] != key: node13a[].children[i].add(node13.children[i][j])
      if node13a[].children.isnil(): node13a = nil
      func isnil[T](arr: array[32, ref T]): bool =
        for i in arr:
          if i != nil: return false
        return true
      var node12a = new HMTNode55_59[T, U]
      for i in 0..<32:
        if i == map[11]: node12a[].children[i] = node13a
        else: node12a[].children[i] = node12.children[i]
      if node12a[].children.isnil: node12a = nil
      var node11a = new HMTNode50_54[T, U]
      for i in 0..<32:
        if i == map[10]: node11a[].children[i] = node12a
        else: node11a[].children[i] = node11.children[i]
      if node11a[].children.isnil: node11a = nil
      var node10a = new HMTNode45_49[T, U]
      for i in 0..<32:
        if i == map[9]: node10a[].children[i] = node11a
        else: node10a[].children[i] = node10.children[i]
      if node10a[].children.isnil: node10a = nil
      var node9a = new HMTNode40_44[T, U]
      for i in 0..<32:
        if i == map[8]: node9a[].children[i] = node10a
        else: node9a[].children[i] = node9.children[i]
      if node9a[].children.isnil: node9a = nil
      var node8a = new HMTNode35_39[T, U]
      for i in 0..<32:
        if i == map[7]: node8a[].children[i] = node9a
        else: node8a[].children[i] = node8.children[i]
      if node8a[].children.isnil: node8a = nil
      var node7a = new HMTNode30_34[T, U]
      for i in 0..<32:
        if i == map[6]: node7a[].children[i] = node8a
        else: node7a[].children[i] = node7.children[i]
      if node7a[].children.isnil: node7a = nil
      var node6a = new HMTNode25_29[T, U]
      for i in 0..<32:
        if i == map[5]: node6a[].children[i] = node7a
        else: node6a[].children[i] = node6.children[i]
      if node6a[].children.isnil: node6a = nil
      var node5a = new HMTNode20_24[T, U]
      for i in 0..<32:
        if i == map[4]: node5a[].children[i] = node6a
        else: node5a[].children[i] = node5.children[i]
      if node5a[].children.isnil: node5a = nil
      var node4a = new HMTNode15_19[T, U]
      for i in 0..<32:
        if i == map[3]: node4a[].children[i] = node5a
        else: node4a[].children[i] = node4.children[i]
      if node4a[].children.isnil: node4a = nil
      var node3a = new HMTNode10_14[T, U]
      for i in 0..<32:
        if i == map[2]: node3a[].children[i] = node4a
        else: node3a[].children[i] = node3.children[i]
      if node3a[].children.isnil: node3a = nil
      var node2a = new HMTNode5_9[T, U]
      for i in 0..<32:
        if i == map[1]: node2a[].children[i] = node3a
        else: node2a[].children[i] = node2.children[i]
      if node2a[].children.isnil: node2a = nil
      var node1a = new HMTNode0_4[T, U]
      node1a[].children = node1.children
      for i in 0..<32:
        if i == map[0]: node1a[].children[i] = node2a
        else: node1a[].children[i] = node1.children[i]
      return HMT[T, U](data: node1a[], len: a.len-1)
  return a

func contains*[T, U](a: HMT[T, U], key: T): bool =
  ## Return `true` if `key` exists in the HMT, otherwise `false`.
  try:
    discard a[key]
    return true
  except KeyError:
    return false

func insertIfEmpty*[T, U](a: HMT[T, U], key: T, value: U): (HMT[T, U], bool) =
  ## Insert `key` with `value` only if `key` is not already present.
  ## Returns `(updatedHMT, inserted?)` where `inserted?` is `true`
  ## when the key was newly inserted.
  if a.contains(key): return (a, false)
  else: return (insert(a, key, value), true)

func pop*[T, U](a: HMT[T, U], key: T): (bool, HMT[T, U], U) =
  ## Remove `key` from the HMT and return `(found?, value)`.
  try:
    let value = a[key]
    return (true, a.del(key), value)
  except KeyError:
    var x: U
    return (false, a, x)

func toHMT*[T, U](a: Table[T, U]): HMT[T, U] =
  ## Convert a `Table[T, U]` (from `std/tables`) into a `HMT[T, U]`.
  result = initHMT[T, U]()
  for i in pairs(a):
    result = result.insert(i[0], i[1])

func toHMT*[T, U](a: openArray[(T, U)]): HMT[T, U] =
  ## Build a `HMT[T, U]` from an open array of `(T, U)` pairs.
  result = initHMT[T, U]()
  for i in a:
    result = result.insert(i[0], i[1])

iterator pairs*[T, U](a: HMT[T, U]): (T, U) {.noSideEffect.} =
  ## Iterate over all key/value pairs stored in the HMT.
  ## Yields each pair as a `(T, U)` tuple. Order is unspecified.
  iterator pairs[T, U](a: HMTNode60_63[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      for j in i:
        yield j
  iterator pairs[T, U](a: HMTNode55_59[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode50_54[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode45_49[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode40_44[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode35_39[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode30_34[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode25_29[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode20_24[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode15_19[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode10_14[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode5_9[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  iterator pairs[T, U](a: HMTNode0_4[T, U]): (T, U) {.noSideEffect.} =
    for i in a.children:
      if i != nil:
        for j in pairs[T, U](i[]):
          yield j
  for i in pairs[T, U](a.data): yield i

iterator keys*[T, U](a: HMT[T, U]): T {.noSideEffect.} =
  ## Iterate over all keys in the HMT. Yields keys of type `T`.
  for i in a.pairs(): yield i[0]

iterator values*[T, U](a: HMT[T, U]): U {.noSideEffect.} =
  ## Iterate over all values in the HMT. Yields values of type `U`.
  for i in a.pairs(): yield i[1]

func len*[T, U](a: HMT[T, U]): int =
  ## Return the number of elements stored in the HMT.
  return a.len.int

func `==`*[T, U](a, b: HMT[T, U]): bool =
  ## Compare two HMT instances for equality.
  ##
  ## This performs a structural equality check of all stored
  ## key/value pairs. Returning `true` means both HMTs contain the
  ## same keys with equal values (based on Nim's `==` for `T`/`U`).
  if a.len != b.len: return false
  for i in pairs(a):
    try:
      if b[i[0]] != i[1]: return false
    except KeyError: return false
  return true

func merge*[T, U](a, b: HMT[T, U]): HMT[T, U] =
  ## Merge two HMTs into a new HMT containing entries from both.
  ## Conflict resolution always prefers the first element.
  result = a
  for i in pairs(b):
    result = result.insertIfEmpty(i[0], i[1])[0]

func hash*[T, U](a: HMT[T, U]): Hash =
  ## Compute a stable `Hash` for the HMT's contents.
  ##
  ## The hash should depend only on the set of key/value pairs and
  ## their values (order independent).
  result = hash(false)
  for i in pairs(a):
    result = result !& hash(i[0])
    result = result !& hash(i[1])
