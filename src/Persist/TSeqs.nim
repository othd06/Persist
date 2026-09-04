
type
    TSeqNode[T] = object
        len: uint64
        hasSpace: bool # determined if the node has space to append into
        targetDepth: uint8 #the depth of the tree at which point it is considered full
        case leaf: bool
            of true:
                offset: uint8
                data: ref array[64, T]
            of false:
                children: array[64, ref TSeqNode[T]]
    TSeq*[T] = ref TSeqNode[T]

func m*[T](a: TSeq[T]): int =
    ## Returns 64^(the height of a)
    ## This is the value that determines the time complexity of many operations
    return 64^a[].targetDepth

func mTrue*[T](a: TSeq[T]): int =
    ## Returns the number of real and virtual elements in the non-growable part of a TSeq
    ## This is the value that m ultimately derives from
    ## If this is significantly higher than len, consider defragmenting
    result = 0
    for i in a[].children:
        if i == nil: break
        if i[].leaf:
            result += i[].len + i[].offset
        else:
            if i[].hasSpace:
                result += mTrue(i[])
            else:
                result += m(i[])

func initTSeq*[T](targetDepth: uint8 = 0): TSeq[T] =
    if targetDepth == 0:
        return TSeq[T](new TSeqNode(len: 0, hasSpace: true, targetDepth: 0, leaf: true, offset: 0, data: new array[64, T]))
    else:
        return TSeq[T](new TSeqNode(len: 0, hasSpace: true, targetDepth: targetDepth, leaf: false, children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]))

func dummySeq[T](targetDepth: uint8): TSeq[T] =
    #for creating dummy nodes that exist at the left hand side of their parent node when a whole child node has been dropped. This mechanism is analagous to the use of offset in leaf nodes
    if targetDepth == 0:
        return TSeq[T](new TSeqNode(len: 0, hasSpace: false, targetDepth: 0, leaf: true))
    else:
        return TSeq[T](new TSeqNode(len: 0, hasSpace: false, targetDepth: targetDepth, leaf: false, children: [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]))

iterator items*[T](a: TSeq[T]): T =
    iterator items[T](a: TSeqNode[T]): T =
        if a.leaf == true:
            if a.len > 0:
                let data = a.data[]
                for i in a.offset..<a.offset+a.len:
                    yield data[i]
        else:
            for i in a.children:
                if i == nil: continue
                for j in i[]:
                    yield j
    for i in a: yield i

func add*[T](a: TSeq[T], elem: T): TSeq[T] =
    func addH*[T](a: ref TSeqNode[T], elem: T): (ref TSeqNode[T], bool) =
        if a.hasSpace:
            if a.leaf:
                result = initTSeq[T]()
                for i in 0..<a[].len:
                    result[].data[i] = a[].data[i + a[].offset]
                result[].data[a[].len] = elem
                result.len = a[].len + 1
                result[].hasSpace = result[].len < 64
                return (result, result[].hasSpace)
            else:
                for idx in 0..<64:
                    let i = if a[].children[idx] == nil: initTSeq[T](a[].targetDepth-1) else: a[].children[idx] # This is fine since we weren't modifying the child in place anyway but were instead replacing it in the new result, we just need something we can hand down recursively
                    if i.hasSpace:
                        let updatedChild = addH(i, elem)
                        result = initTSeq[T](a[].targetDepth)
                        result[].len = a[].len + 1
                        result[].hasSpace = updatedChild[1] or idx < 63
                        for j in 0..<idx:
                            result[].children[j] = a[].children[j]
                        result[].children[idx] = updatedChild[0]
                        return result
                assert(false, "something has gone wrong")
        else:
            result = initTSeq[T](a[].targetDepth+1)
            result.len = a[].len + 1
            result.children[0] = a
            result.children[1] = initTSeq[T](a[].targetDepth).addH(elem)[0]
            return result
    return addH(a, elem)[0]

func `%`*[T](a: openArray[T]): TSeq[T] =
    ## Turns an _OpenArray_ into a TSeq
    if a.len == 0: return initTSeq[T]()
    var tree: seq[seq[TSeq]]
    tree.add(@[])
    for i in 0..<(a.len + 63) shr 6:
        var newNode = initTSeq[T]()
        for j in 0..<min(64, a.len-(i shl 6)):
            newNode[].data[j] = a[(i shl 6) + j]
            if j == 63: newNode[].hasSpace = false
            newNode[].len = j+1
        tree[0].add(newNode)
    while tree[^1].len() > 1:
        let targetDepth = tree.len
        tree.add(@[])
        for i in 0..<(tree[^2].len + 63) shr 6:
            var newNode = initTSeq[T](targetDepth)
            for j in 0..<min(64, tree[^2].len-(i shl 6)):
                newNode[].children[j] = tree[^2][(i shl 6) + j]
                if j == 63: newNode[].hasSpace = tree[^2][(i shl 6) + j][].hasSpace
                newNode[].len += tree[^2][(i shl 6) + j][].len
            tree[^1].add(newNode)
    return tree[^1][0]

func defrag*[T](a: var TSeq[T]) =
    var
        aseq = newSeq[T](a.len)
        idx = 0
    for i in a:
        aseq[idx] = i
        idx += 1
    a = (% aseq)

func `[]`*[T](a: TSeq[T], idx: Natural): T =
    if idx >= a.len:
        raise newException(RangeDefect, "attempting to index TList out of bounds")
    var
        range_start = 0
        range_end = a.len
        node = a
    while not node.leaf:
        for i in node.children:
            if i == nil: continue
            if i[].len + range_start <= idx:
                range_start = i[].len + range_start
            else:
                range_end = i[].len + range_start
                node = i[]
                break
        assert(range_start <= idx and range_end > idx)
        assert(range_end - range_start == node.len)
    return node.data[node.offset+idx-range_start]

func toSeq*[T](a: TSeq[T]): seq[T] =
    return

func replace*[T](a: TSeq[T], elem: T, idx: Natural): TSeq[T] =
    return

func len*[T](a: TSeq[T]): int =
    return a.len.int

func insert*[T](a: TSeq[T], elem: T, idx: Natural): TSeq[T] =
    return

func del*[T](a: TSeq[T], idx: Natural): TSeq[T] =
    return

func del*[T](a: TSeq[T], idxs: Slice[Natural]): TSeq[T] =
    result = a
    var idx: Natural
    for i in idxs: idx = i; break
    for i in idxs:
        result = result.del(idx)

func delete*[T](a: TSeq[T], idx: Natural): TSeq[T] =
    return

func delete*[T](a: TSeq[T], idxs: Slice[Natural]): TSeq[T] =
    result = a
    var idx: Natural
    for i in idxs: idx = i; break
    for i in idxs:
        result = result.delete(idx)

func pop*[T](a: TSeq[T]): (T, TSeq[T]) =
    return (a[a.len-1], a.delete(a.len-1))

func `&`*[T](a, b: TSeq[T]): TSeq[T] =
    return

func addUnique*[T](a: TSeq[T], elem: T): TSeq[T] =
    return

func all*[T](a: TSeq[T]; fun: proc (x: T): bool {.noSideEffect.}): bool =
    return

func any*[T](a: TSeq[T]; fun: proc (x: T): bool {.noSideEffect.}): bool =
    return

func concat*[T](a, b: TSeq[T]): TSeq[T] = a & b

func count*[T](a: TSeq[T], elem: T): int =
    return

func cycle*[T](a: TSeq[T], count: int): TSeq[T] =
    var result = a
    for i in 1..<count:
        for j in a:
            result = result.add(j)

func deduplicate*[T](a: TSeq[T]): TSeq[T] =
    return

func filter*[T](a: TSeq[T]; fun: proc (x: T): bool {.noSideEffect.}): TSeq[T] =
    var
        mapseq: seq[T] = @[]
    for i in a:
        if not fun(i): continue
        mapseq.add(i)
    return (% mapseq)

func map*[T, U](a: TSeq[T]; fun: proc (x: T): U {.noSideEffect.}): TSeq[U] =
    var
        mapseq: seq[U] = newSeq[U](a.len)
        idx = 0
    for i in a:
        mapseq[idx] = fun(i)
        idx += 1
    return (% mapseq)

func insert*[T](a, b: TSeq[T], idx: int): TSeq[T] =
    return

func maxIndex*[T](a: TSeq[T], cmp: proc(a, b: T): int {.noSideEffect.}): int =
    result = 0
    var currMax = a[0]
    for i in 0..<a.len:
        if cmp(a[i], currMax) == 1:
            currMax = a[i]
            result = i

func max*[T](a: TSeq[T], cmp: proc(a, b: T): int {.noSideEffect.}): T =
    result = a[0]
    for i in a:
        if cmp(i, result) == 1: result = i

func minIndex*[T](a: TSeq[T], cmp: proc(a, b: T): int {.noSideEffect.}): int =
    result = 0
    var currMin = a[0]
    for i in 0..<a.len:
        if cmp(a[i], currMin) == -1:
            currMin = a[i]
            result = i

func min*[T](a: TSeq[T], cmp: proc(a, b: T): int {.noSideEffect.}): T =
    result = a[0]
    for i in a:
        if cmp(i, result) == -1: result = i

func minmaxIndex*[T](a: TSeq[T], cmp: proc(a, b: T): int {.noSideEffect.}): (int, int) =
    result = (0, 0)
    var
        currMax = a[0]
        currMin = a[0]
    for i in 0..<a.len:
        if cmp(a[i], currMax) == 1:
            currMax = a[i]
            result[1] = i
        elif cmp(a[i], currMin) == -1:
            currMin = a[i]
            result[0] = i 

func minmax*[T](a: TSeq[T], cmp: proc(a, b: T): int {.noSideEffect.}): (T, T) =
    result = (a[0], a[0])
    for i in 0..<a.len:
        if cmp(a[i], result[1]) == 1: result[1] = a[i]
        elif cmp(a[i], result[0]) == -1: result[0] = a[i]

func repeat*[T](x: T, n: Natural): TSeq[T] =
    return

func unzip*[T, U](a: TSeq[(T, U)]): (TSeq[T], TSeq[U]) =
    return

func zip*[T, U](a: TSeq[T], b: TSeq[U]): TSeq[(T, U)] =
    return

func take*[T](a: TSeq[T], b: Natural): TSeq[T] =
    return

func takeWhile*[T](a: TSeq[T]; fun: proc(x: T): bool {.noSideEffect.}): TSeq[T] =
    return

func drop*[T](a: TSeq[T], b: Natural): TSeq[T] =
    return

func dropWhile*[T](a: TSeq[T]; fun: proc(x: T): bool {.noSideEffect.}): TSeq[T] =
    return

func foldl*[T, U](a: TSeq[T], fun: proc(e: T, z: U): U {.noSideEffect.}, z: U): U =
    return

func foldr*[T, U](a: TSeq[T], fun: proc(e: T, z: U): U {.noSideEffect.}, z: U): U =
    return

func reverse*[T](a: TSeq[T]): TSeq[T] =
    return

