
import HMTs
import std/hashes

type
    PSet*[T] = distinct HMT[T, T]

iterator items*[T](a: PSet[T]): T {.noSideEffect.} =
    ## Iterate over items stored in the set. Order is unspecified.
    for i in keys(cast[HMT[T, T]](a)): yield i

func initPSet*[T](): PSet[T] =
    ## Create an empty `PSet`.
    ## Returns a new, empty persistent set for elements of type `T`.
    return PSet[T](initHMT[T, T]())

func incl*[T](a: PSet[T], value: T): PSet[T] =
    ## Return a new set containing `value` (inserting it if missing).
    return PSet[T](HMT[T, T](a).insert(value, value))

func len*[T](a: PSet[T]): int =
    ## Number of elements in the set.
    return HMT[T, T](a).len()

func `$`*[T](a: PSet[T]): string =
    ## Convert a `PSet` to a string.
    ## The representation is implementation-defined; this routine should
    ## produce a readable string useful for debugging and logging.
    if a.len() == 0: return "{}"
    result = "{"
    for i in a:
        result = result & $i & ", "
    result = result[0..result.high-2] & "}"

func `==`*[T](a, b: PSet[T]): bool =
    ## Compare two `PSet`s for equality.
    ## Two sets are equal when they contain the same elements.
    return cast[HMT[T, T]](a) == cast[HMT[T, T]](b)

func contains*[T](a: PSet[T], value: T): bool =
    ## Return `true` if `value` is present in the set.
    return cast[HMT[T, T]](a).contains(value)

func intersection*[T](a, b: PSet[T]): PSet[T] =
    ## Set intersection: elements present in both `a` and `b`.
    result = initPSet[T]()
    for i in a:
        if b.contains(i): result = result.incl(i)

func union*[T](a, b: PSet[T]): PSet[T] =
    ## Set union: elements present in `a` or `b` (or both).
    result = initPSet[T]()
    for i in a:
        result = result.incl(i)
    for i in b:
        result = result.incl(i)

func difference*[T](a, b: PSet[T]): PSet[T] =
    ## Set difference: elements in `a` that are not in `b`.
    result = initPSet[T]()
    for i in a:
        if not b.contains(i): result = result.incl(i)

func symmetricDifference*[T](a, b: PSet[T]): PSet[T] =
    ## Symmetric difference: elements in exactly one of `a` or `b`.
    result = initPSet[T]()
    for i in a:
        if not b.contains(i): result = result.incl(i)
    for i in b:
        if not a.contains(i): result = result.incl(i)
    #return difference(union(a, b), intersection(a, b))

func subset*[T](a, b: PSet[T]): bool =
    ## Return `true` if `a` is a subset of `b` (every element of `a` is in `b`).
    if a.len() > b.len(): return false
    for i in a:
        if not b.contains(i): return false
    return true

func properSubset*[T](a, b: PSet[T]): bool =
    ## Return `true` if `a` is a proper subset of `b` (`a` subset of `b` and sizes differ).
    return len(a) < len(b) and a.subset(b)

func containsOrIncl*[T](a: PSet[T], value: T): (bool, PSet[T]) =
    ## Check membership but also return a set with the value included.
    ## Returns `(present?, updatedSet)` where `present?` is `true` if
    ## `value` was already in the set, and `updatedSet` is the set with
    ## `value` present (equal to `a` when already present).
    if a.contains(value): return (true, a)
    else: return (false, a.incl(value))

func disjoint*[T](a, b: PSet[T]): bool =
    ## Return `true` when `a` and `b` are disjoint (no shared elements).
    for i in a:
        if b.contains(i): return false
    return true

func excl*[T](a: PSet[T], value: T): PSet[T] =
    ## Return a set with `value` excluded (removed).
    return PSet[T](cast[HMT[T, T]](a).del(value))

func hash*[T](a: PSet[T]): Hash =
    ## Compute a stable `Hash` for the set contents.
    ## The hash must depend only on the set of elements (order-independent).
    return hash(false) !& hash(cast[HMT[T, T]](a))

func map*[T, U](a: PSet[T], fun: proc (x: T): U {.noSideEffect.}): PSet[U] =
    ## Map each element of the set with `fun` and return a `PSet[U]`.
    ## The mapping function must be pure (no side-effects) and may change
    ## element type. Duplicate results are collapsed into a set.
    result = initPSet[U]()
    for i in a:
        result = result.incl(fun(i))

func missingOrExcl*[T](a: PSet[T], value: T): (bool, PSet[T]) =
    ## Check whether `value` was missing, and return a set with it excluded.
    ## Returns `(wasMissing?, updatedSet)` where `wasMissing?` is `true`
    ## if `value` was not present in the original set.
    if a.contains(value):
        return (false, a.excl(value))
    else:
        return (true, a)

func pop*[T](a: PSet[T]): (T, PSet[T]) =
    ## Pop an arbitrary element from the set, returning `(element, newSet)`.
    ## Behaviour is unspecified when the set is empty.
    for i in a:
        return (i, a.excl(i))
    raise newException(KeyError, "trying to pop from an empty PSet")

