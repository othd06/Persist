import unittest
import Persist/HMTs
import Persist/PSets
import std/tables
import std/sets
import Persist/TCOsFast
import Persist/TSeqs

suite "HMT Basic Operations":
  test "initHMT creates empty HMT":
    let hmt = initHMT[string, int]()
    check hmt.len == 0

  test "insert and retrieve single element":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("key1", 42)
    check hmt.contains("key1")
    check hmt["key1"] == 42
    check hmt.len == 1

  test "insert multiple elements":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    hmt = hmt.insert("c", 3)
    check hmt["a"] == 1
    check hmt["b"] == 2
    check hmt["c"] == 3
    check hmt.len == 3

  test "retrieving missing key raises KeyError":
    let hmt = initHMT[string, int]()
    expect KeyError:
      discard hmt["nonexistent"]

  test "contains returns true/false correctly":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("key1", 42)
    check hmt.contains("key1") == true
    check hmt.contains("missing") == false

  test "getOrDefault with existing key":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("key1", 42)
    check hmt.getOrDefault("key1", 99) == 42

  test "getOrDefault with missing key":
    let hmt = initHMT[string, int]()
    check hmt.getOrDefault("missing", 99) == 99

suite "HMT Mutations":
  test "update existing key":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("key1", 42)
    hmt = hmt.insert("key1", 100)
    check hmt["key1"] == 100
    check hmt.len == 1

  test "delete existing key":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    hmt = hmt.del("a")
    check hmt.contains("a") == false
    check hmt.contains("b") == true
    check hmt.len == 1

  test "delete non-existent key returns unchanged HMT":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    let original_len = hmt.len
    hmt = hmt.del("missing")
    check hmt.len == original_len
    check hmt.contains("a") == true

  test "insertIfEmpty with new key":
    var hmt = initHMT[string, int]()
    let (hmt2, inserted) = hmt.insertIfEmpty("key1", 42)
    check inserted == true
    check hmt2["key1"] == 42

  test "insertIfEmpty with existing key":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("key1", 42)
    let (hmt2, inserted) = hmt.insertIfEmpty("key1", 99)
    check inserted == false
    check hmt2["key1"] == 42

  test "pop existing key":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("key1", 42)
    let (found, hmt2, value) = hmt.pop("key1")
    check found == true
    check value == 42
    check hmt2.contains("key1") == false

  test "pop missing key":
    let hmt = initHMT[string, int]()
    let (found, hmt2, _) = hmt.pop("missing")
    check found == false
    check hmt2.len == 0

suite "HMT Iterators":
  test "keys iterator":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    hmt = hmt.insert("c", 3)
    var keys_found: seq[string] = @[]
    for k in hmt.keys():
      keys_found.add(k)
    check keys_found.len == 3
    check "a" in keys_found
    check "b" in keys_found
    check "c" in keys_found

  test "values iterator":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    hmt = hmt.insert("c", 3)
    var values_found: seq[int] = @[]
    for v in hmt.values():
      values_found.add(v)
    check values_found.len == 3
    check 1 in values_found
    check 2 in values_found
    check 3 in values_found

  test "pairs iterator":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    var pairs_found: seq[(string, int)] = @[]
    for k, v in hmt.pairs():
      pairs_found.add((k, v))
    check pairs_found.len == 2
    check ("a", 1) in pairs_found
    check ("b", 2) in pairs_found

suite "HMT Comparison and Hashing":
  test "equality of identical HMTs":
    var hmt1 = initHMT[string, int]()
    var hmt2 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)
    hmt2 = hmt2.insert("a", 1)
    check hmt1 == hmt2

  test "inequality with different values":
    var hmt1 = initHMT[string, int]()
    var hmt2 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)
    hmt2 = hmt2.insert("a", 2)
    check hmt1 != hmt2

  test "inequality with different keys":
    var hmt1 = initHMT[string, int]()
    var hmt2 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)
    hmt2 = hmt2.insert("b", 1)
    check hmt1 != hmt2

  test "hash function produces hash":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    let h = hash(hmt)
    discard h
    # Just check that a hash is produced, not checking specific value

suite "HMT Merging":
  test "merge two HMTs":
    var hmt1 = initHMT[string, int]()
    var hmt2 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)
    hmt1 = hmt1.insert("b", 2)
    hmt2 = hmt2.insert("c", 3)
    hmt2 = hmt2.insert("d", 4)
    var merged = hmt1.merge(hmt2)
    check merged.contains("a") == true
    check merged.contains("b") == true
    check merged.contains("c") == true
    check merged.contains("d") == true

  test "merge with overlapping keys prefers first HMT":
    var hmt1 = initHMT[string, int]()
    var hmt2 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)
    hmt2 = hmt2.insert("a", 99)
    var merged = hmt1.merge(hmt2)
    check merged["a"] == 1

suite "HMT Type Flexibility":
  test "int key, string value":
    var hmt = initHMT[int, string]()
    hmt = hmt.insert(42, "answer")
    hmt = hmt.insert(1, "one")
    check hmt[42] == "answer"
    check hmt[1] == "one"

  test "conversion from Table":
    let t: Table[string, int] = {"x": 10, "y": 20}.toTable
    let hmt = t.toHMT()
    check hmt.contains("x") == true
    check hmt.contains("y") == true
    check hmt["x"] == 10
    check hmt["y"] == 20

  test "conversion from openArray":
    let pairs = [("a", 1), ("b", 2), ("c", 3)]
    var hmt = pairs.toHMT()
    check hmt["a"] == 1
    check hmt["b"] == 2
    check hmt["c"] == 3

  test "openArray conversion handles duplicate keys":
    let pairs = [
      ("a", 1),
      ("b", 2),
      ("a", 3)
    ]
    let hmt = pairs.toHMT()
    check hmt.len == 2
    check hmt["a"] == 3
    check hmt["b"] == 2

suite "HMT Stress Tests":
  test "many insertions":
    var hmt = initHMT[int, int]()
    for i in 0..<100:
      hmt = hmt.insert(i, i * 2)
    check hmt.len == 100
    for i in 0..<100:
      check hmt[i] == i * 2

  test "many insertions and deletions":
    var hmt = initHMT[int, int]()
    for i in 0..<50:
      hmt = hmt.insert(i, i * 2)
    check hmt.len == 50
    for i in 0..<25:
      hmt = hmt.del(i)
    check hmt.len == 25
    for i in 25..<50:
      check hmt.contains(i) == true

  test "overwriting many values":
    var hmt = initHMT[string, int]()
    for i in 0..<50:
      hmt = hmt.insert("key", i)
    check hmt.len == 1
    check hmt["key"] == 49

  test "deletion-heavy workload agrees with Table":
    var hmt = initHMT[int, int]()
    var table = initTable[int, int]()

    for i in 0..<500:
      hmt = hmt.insert(i, i * 10)
      table[i] = i * 10

    for step in 0..<2000:
      let key = (step * 73 + 19) mod 500

      if step mod 3 == 0:
        let value = step * 7
        hmt = hmt.insert(key, value)
        table[key] = value
      else:
        hmt = hmt.del(key)
        table.del(key)

      check hmt.len == table.len

      for k, v in table.pairs:
        check hmt.contains(k)
        check hmt[k] == v

      var count = 0

      for k, v in hmt.pairs():
        check table.hasKey(k)
        check table[k] == v
        inc count

      check count == table.len

suite "HMT Persistence":
  test "insert does not mutate previous version":
    var hmt1 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)

    let hmt2 = hmt1.insert("b", 2)

    check hmt1.len == 1
    check hmt1.contains("a")
    check not hmt1.contains("b")
    check hmt1["a"] == 1

    check hmt2.len == 2
    check hmt2["a"] == 1
    check hmt2["b"] == 2

  test "update does not mutate previous version":
    var hmt1 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)

    let hmt2 = hmt1.insert("a", 99)

    check hmt1.len == 1
    check hmt1["a"] == 1

    check hmt2.len == 1
    check hmt2["a"] == 99

  test "delete does not mutate previous version":
    var hmt1 = initHMT[string, int]()
    hmt1 = hmt1.insert("a", 1)
    hmt1 = hmt1.insert("b", 2)

    let hmt2 = hmt1.del("a")

    check hmt1.len == 2
    check hmt1["a"] == 1
    check hmt1["b"] == 2

    check hmt2.len == 1
    check not hmt2.contains("a")
    check hmt2["b"] == 2

  test "multiple descendants preserve common ancestor":
    var base = initHMT[string, int]()
    base = base.insert("a", 1)

    let left = base.insert("b", 2)
    let right = base.insert("c", 3)

    check base.len == 1
    check base["a"] == 1
    check not base.contains("b")
    check not base.contains("c")

    check left.len == 2
    check left["a"] == 1
    check left["b"] == 2
    check not left.contains("c")

    check right.len == 2
    check right["a"] == 1
    check right["c"] == 3
    check not right.contains("b")

  test "long version chain preserves all historical states":
    var versions: seq[HMT[int, int]] = @[]
    var hmt = initHMT[int, int]()

    versions.add(hmt)

    for i in 0..<50:
      hmt = hmt.insert(i, i * 10)
      versions.add(hmt)

    for versionIndex in 0..50:
      let version = versions[versionIndex]

      check version.len == versionIndex

      for i in 0..<versionIndex:
        check version.contains(i)
        check version[i] == i * 10

      for i in versionIndex..<50:
        check not version.contains(i)

  test "deleting from descendant does not affect ancestor or sibling":
    var base = initHMT[string, int]()
    base = base.insert("a", 1)
    base = base.insert("b", 2)
    base = base.insert("c", 3)

    let left = base.del("a")
    let right = base.del("b")

    check base.len == 3
    check base["a"] == 1
    check base["b"] == 2
    check base["c"] == 3

    check left.len == 2
    check not left.contains("a")
    check left["b"] == 2
    check left["c"] == 3

    check right.len == 2
    check right["a"] == 1
    check not right.contains("b")
    check right["c"] == 3

suite "HMT Iterators After Mutation":
  test "pairs after deletions contains exactly remaining entries":
    var hmt = initHMT[int, int]()

    for i in 0..<100:
      hmt = hmt.insert(i, i * 2)

    for i in 0..<100:
      if i mod 2 == 0:
        hmt = hmt.del(i)

    var found = initTable[int, int]()

    for k, v in hmt.pairs():
      found[k] = v

    check found.len == 50
    check found.len == hmt.len

    for i in 0..<100:
      if i mod 2 == 0:
        check not found.hasKey(i)
      else:
        check found.hasKey(i)
        check found[i] == i * 2

  test "keys after insert update and delete":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    hmt = hmt.insert("c", 3)
    hmt = hmt.insert("b", 200)
    hmt = hmt.del("a")
    hmt = hmt.insert("d", 4)

    var found: seq[string] = @[]

    for k in hmt.keys():
      found.add(k)

    check found.len == hmt.len
    check found.len == 3
    check "b" in found
    check "c" in found
    check "d" in found
    check "a" notin found

  test "values after insert update and delete":
    var hmt = initHMT[string, int]()
    hmt = hmt.insert("a", 1)
    hmt = hmt.insert("b", 2)
    hmt = hmt.insert("c", 3)
    hmt = hmt.insert("b", 200)
    hmt = hmt.del("a")
    hmt = hmt.insert("d", 4)

    var found: seq[int] = @[]

    for v in hmt.values():
      found.add(v)

    check found.len == hmt.len
    check found.len == 3
    check 200 in found
    check 3 in found
    check 4 in found
    check 1 notin found
    check 2 notin found

  test "iterator count always matches len during mutations":
    var hmt = initHMT[int, int]()

    for i in 0..<100:
      hmt = hmt.insert(i, i)

      var count = 0
      for _ in hmt.pairs():
        inc count

      check count == hmt.len

    for i in 0..<100:
      if i mod 3 == 0:
        hmt = hmt.del(i)

        var count = 0
        for _ in hmt.pairs():
          inc count

        check count == hmt.len

  test "iterator values agree with lookup":
    var hmt = initHMT[int, int]()

    for i in 0..<100:
      hmt = hmt.insert(i, i * i)

    for i in 20..<80:
      if i mod 4 == 0:
        hmt = hmt.del(i)

    for k, v in hmt.pairs():
      check hmt.contains(k)
      check hmt[k] == v

  test "old version iterators remain valid after descendant mutations":
    var old = initHMT[int, int]()

    for i in 0..<20:
      old = old.insert(i, i)

    var current = old

    for i in 0..<10:
      current = current.del(i)

    for i in 20..<30:
      current = current.insert(i, i)

    var oldCount = 0
    for k, v in old.pairs():
      check k == v
      check k >= 0
      check k < 20
      inc oldCount

    check oldCount == 20

    var currentCount = 0
    for k, v in current.pairs():
      check k == v
      check k >= 10
      check k < 30
      inc currentCount

    check currentCount == 20


suite "HMT Differential Testing":
  test "mixed operations agree with Table":
    var hmt = initHMT[int, int]()
    var table = initTable[int, int]()

    for step in 0..<5000:
      let key = (step * 37 + 11) mod 200
      let value = step * 17

      case step mod 5
      of 0, 1, 2:
        hmt = hmt.insert(key, value)
        table[key] = value

      of 3:
        hmt = hmt.del(key)
        table.del(key)

      of 4:
        check hmt.contains(key) == table.hasKey(key)

        if table.hasKey(key):
          check hmt[key] == table[key]
        else:
          expect KeyError:
            discard hmt[key]

      else:
        discard

      check hmt.len == table.len

      for k, v in table.pairs:
        check hmt.contains(k)
        check hmt[k] == v

      var iterated = initTable[int, int]()

      for k, v in hmt.pairs():
        iterated[k] = v

      check iterated.len == table.len

      for k, v in table.pairs:
        check iterated.hasKey(k)
        check iterated[k] == v

suite "Empty HMT":
  test "empty HMT has length zero":
    let hmt = initHMT[string, int]()
    check hmt.len == 0

  test "empty HMT contains no keys":
    let hmt = initHMT[string, int]()
    check not hmt.contains("a")
    check not hmt.contains("")

  test "lookup in empty HMT raises KeyError":
    let hmt = initHMT[string, int]()

    expect KeyError:
      discard hmt["a"]

  test "getOrDefault works on empty HMT":
    let hmt = initHMT[string, int]()
    check hmt.getOrDefault("a", 123) == 123

  test "pairs iterator on empty HMT yields nothing":
    let hmt = initHMT[string, int]()

    var count = 0
    for _ in hmt.pairs():
      inc count

    check count == 0

  test "keys iterator on empty HMT yields nothing":
    let hmt = initHMT[string, int]()

    var count = 0
    for _ in hmt.keys():
      inc count

    check count == 0

  test "values iterator on empty HMT yields nothing":
    let hmt = initHMT[string, int]()

    var count = 0
    for _ in hmt.values():
      inc count

    check count == 0

  test "two empty HMTs are equal":
    let a = initHMT[string, int]()
    let b = initHMT[string, int]()

    check a == b

  test "two empty HMTs have equal hashes":
    let a = initHMT[string, int]()
    let b = initHMT[string, int]()

    check hash(a) == hash(b)

  test "deleting from empty HMT remains empty":
    let a = initHMT[string, int]()
    let b = a.del("missing")

    check a.len == 0
    check b.len == 0
    check a == b

  test "pop from empty HMT":
    let hmt = initHMT[string, int]()
    let (found, result, _) = hmt.pop("missing")

    check not found
    check result.len == 0

  test "merge two empty HMTs":
    let a = initHMT[string, int]()
    let b = initHMT[string, int]()
    let merged = a.merge(b)

    check merged.len == 0
    check merged == a
    check merged == b


suite "PSet Basic Operations":
  test "initPSet creates empty set":
    let s = initPSet[int]()
    check s.len == 0
    check s == initPSet[int]()

  test "incl adds element":
    var s = initPSet[int]()
    s = s.incl(42)

    check s.len == 1
    check s.contains(42)

  test "incl of existing element does not change size":
    var s = initPSet[int]()
    s = s.incl(42)
    s = s.incl(42)

    check s.len == 1
    check s.contains(42)

  test "contains returns true and false correctly":
    var s = initPSet[string]()
    s = s.incl("a")

    check s.contains("a")
    check not s.contains("b")

  test "items iterator returns every element":
    var s = initPSet[int]()
    for i in 0..<100:
      s = s.incl(i)

    var found = initHashSet[int]()

    for i in s:
      found.incl(i)

    check found.len == s.len

    for i in 0..<100:
      check found.contains(i)


suite "PSet Exclusion":
  test "excl removes existing element":
    var s = initPSet[int]()
    s = s.incl(1)
    s = s.incl(2)

    let result = s.excl(1)

    check result.len == 1
    check not result.contains(1)
    check result.contains(2)

  test "excl missing element leaves set unchanged":
    var s = initPSet[int]()
    s = s.incl(1)
    s = s.incl(2)

    let result = s.excl(3)

    check result == s
    check result.len == 2

  test "containsOrIncl reports missing element":
    var s = initPSet[int]()
    s = s.incl(1)

    let (present, result) = s.containsOrIncl(2)

    check not present
    check result.len == 2
    check result.contains(1)
    check result.contains(2)

  test "containsOrIncl reports existing element":
    var s = initPSet[int]()
    s = s.incl(1)

    let (present, result) = s.containsOrIncl(1)

    check present
    check result == s

  test "missingOrExcl reports present element":
    var s = initPSet[int]()
    s = s.incl(1)
    s = s.incl(2)

    let (missing, result) = s.missingOrExcl(1)

    check not missing
    check result.len == 1
    check not result.contains(1)
    check result.contains(2)

  test "missingOrExcl reports missing element":
    var s = initPSet[int]()
    s = s.incl(1)

    let (missing, result) = s.missingOrExcl(2)

    check missing
    check result == s


suite "PSet Set Operations":
  test "union":
    var a = initPSet[int]()
    var b = initPSet[int]()

    for i in [1, 2, 3]:
      a = a.incl(i)

    for i in [3, 4, 5]:
      b = b.incl(i)

    let result = a.union(b)

    check result.len == 5

    for i in 1..5:
      check result.contains(i)

  test "intersection":
    var a = initPSet[int]()
    var b = initPSet[int]()

    for i in [1, 2, 3]:
      a = a.incl(i)

    for i in [3, 4, 5]:
      b = b.incl(i)

    let result = a.intersection(b)

    check result.len == 1
    check result.contains(3)

  test "difference":
    var a = initPSet[int]()
    var b = initPSet[int]()

    for i in [1, 2, 3]:
      a = a.incl(i)

    for i in [2, 3, 4]:
      b = b.incl(i)

    let result = a.difference(b)

    check result.len == 1
    check result.contains(1)

  test "symmetric difference":
    var a = initPSet[int]()
    var b = initPSet[int]()

    for i in [1, 2, 3]:
      a = a.incl(i)

    for i in [3, 4, 5]:
      b = b.incl(i)

    let result = a.symmetricDifference(b)

    check result.len == 4
    check result.contains(1)
    check result.contains(2)
    check result.contains(4)
    check result.contains(5)
    check not result.contains(3)

  test "subset":
    var a = initPSet[int]()
    var b = initPSet[int]()

    for i in [1, 2]:
      a = a.incl(i)

    for i in [1, 2, 3]:
      b = b.incl(i)

    check a.subset(b)
    check not b.subset(a)

  test "proper subset":
    var a = initPSet[int]()
    var b = initPSet[int]()

    for i in [1, 2]:
      a = a.incl(i)

    for i in [1, 2, 3]:
      b = b.incl(i)

    check a.properSubset(b)
    check not b.properSubset(a)
    check not a.properSubset(a)

  test "disjoint":
    var a = initPSet[int]()
    var b = initPSet[int]()
    var c = initPSet[int]()

    a = a.incl(1).incl(2)
    b = b.incl(3).incl(4)
    c = c.incl(2).incl(5)

    check a.disjoint(b)
    check not a.disjoint(c)
    check b.disjoint(a)


suite "PSet Set Algebra":
  test "union is commutative":
    var a = initPSet[int]()
    var b = initPSet[int]()

    a = a.incl(1).incl(2).incl(3)
    b = b.incl(3).incl(4).incl(5)

    check a.union(b) == b.union(a)

  test "intersection is commutative":
    var a = initPSet[int]()
    var b = initPSet[int]()

    a = a.incl(1).incl(2).incl(3)
    b = b.incl(3).incl(4).incl(5)

    check a.intersection(b) == b.intersection(a)

  test "union with itself is itself":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    check a.union(a) == a

  test "intersection with itself is itself":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    check a.intersection(a) == a

  test "difference with itself is empty":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    check a.difference(a).len == 0

  test "union with empty is itself":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    let empty = initPSet[int]()

    check a.union(empty) == a
    check empty.union(a) == a

  test "intersection with empty is empty":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    let empty = initPSet[int]()

    check a.intersection(empty).len == 0
    check empty.intersection(a).len == 0

  test "symmetric difference with itself is empty":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    check a.symmetricDifference(a).len == 0

  test "subset is reflexive":
    var a = initPSet[int]()
    a = a.incl(1).incl(2).incl(3)

    check a.subset(a)

  test "disjoint is symmetric":
    var a = initPSet[int]()
    var b = initPSet[int]()

    a = a.incl(1).incl(2)
    b = b.incl(2).incl(3)

    check a.disjoint(b) == b.disjoint(a)


suite "PSet Persistence":
  test "incl preserves previous version":
    var original = initPSet[int]()
    original = original.incl(1)

    let updated = original.incl(2)

    check original.len == 1
    check original.contains(1)
    check not original.contains(2)

    check updated.len == 2
    check updated.contains(1)
    check updated.contains(2)

  test "excl preserves previous version":
    var original = initPSet[int]()
    original = original.incl(1).incl(2).incl(3)

    let updated = original.excl(2)

    check original.len == 3
    check original.contains(1)
    check original.contains(2)
    check original.contains(3)

    check updated.len == 2
    check updated.contains(1)
    check not updated.contains(2)
    check updated.contains(3)

  test "branching versions remain independent":
    var base = initPSet[int]()
    base = base.incl(1)

    let left = base.incl(2)
    let right = base.incl(3)

    check base.len == 1
    check base.contains(1)

    check left.len == 2
    check left.contains(1)
    check left.contains(2)
    check not left.contains(3)

    check right.len == 2
    check right.contains(1)
    check right.contains(3)
    check not right.contains(2)

  test "long version chain preserves all historical states":
    var versions: seq[PSet[int]] = @[]
    var current = initPSet[int]()

    versions.add(current)

    for i in 0..<50:
      current = current.incl(i)
      versions.add(current)

    for versionIndex in 0..50:
      let version = versions[versionIndex]

      check version.len == versionIndex

      for i in 0..<versionIndex:
        check version.contains(i)

      for i in versionIndex..<50:
        check not version.contains(i)


suite "PSet Pop":
  test "pop removes exactly one element":
    var s = initPSet[int]()
    s = s.incl(1).incl(2).incl(3)

    let (value, result) = s.pop()

    check result.len == 2
    check s.len == 3
    check s.contains(value)
    check not result.contains(value)

    for i in s:
      if i != value:
        check result.contains(i)

  test "pop from singleton produces empty set":
    var s = initPSet[int]()
    s = s.incl(42)

    let (value, result) = s.pop()

    check value == 42
    check result.len == 0
    check s.len == 1


suite "PSet Map":
  test "map preserves cardinality when mapping is injective":
    var s = initPSet[int]()

    for i in 0..<10:
      s = s.incl(i)

    let result = s.map(proc(x: int): int = x * 2)

    check result.len == 10

    for i in 0..<10:
      check result.contains(i * 2)

  test "map collapses duplicate results":
    var s = initPSet[int]()

    for i in 0..<10:
      s = s.incl(i)

    let result = s.map(proc(x: int): int = x mod 3)

    check result.len == 3
    check result.contains(0)
    check result.contains(1)
    check result.contains(2)

  test "map can change element type":
    var s = initPSet[int]()
    s = s.incl(1).incl(2).incl(3)

    let result = s.map(proc(x: int): string = $x)

    check result.len == 3
    check result.contains("1")
    check result.contains("2")
    check result.contains("3")


suite "PSet Hashing":
  test "equal sets have equal hashes":
    var a = initPSet[int]()
    var b = initPSet[int]()

    a = a.incl(1).incl(2).incl(3)
    b = b.incl(3).incl(1).incl(2)

    check a == b
    check hash(a) == hash(b)

  test "different sets are not necessarily same hash":
    var a = initPSet[int]()
    var b = initPSet[int]()

    a = a.incl(1)
    b = b.incl(2)

    discard hash(a)
    discard hash(b)


suite "PSet Differential Testing":
  test "mixed operations agree with HashSet":
    var pset = initPSet[int]()
    var hset = initHashSet[int]()

    for step in 0..<5000:
      let value = (step * 37 + 11) mod 200

      case step mod 5
      of 0, 1, 2:
        pset = pset.incl(value)
        hset.incl(value)

      of 3:
        pset = pset.excl(value)
        hset.excl(value)

      of 4:
        check pset.contains(value) == hset.contains(value)

      else:
        discard

      check pset.len == hset.len

      for x in hset:
        check pset.contains(x)

      for x in pset:
        check hset.contains(x)

  test "set operations agree with HashSet semantics":
    var a = initPSet[int]()
    var b = initPSet[int]()

    var ah = initHashSet[int]()
    var bh = initHashSet[int]()

    for i in 0..<100:
      if i mod 2 == 0:
        a = a.incl(i)
        ah.incl(i)

      if i mod 3 == 0:
        b = b.incl(i)
        bh.incl(i)

    let union = a.union(b)
    let intersection = a.intersection(b)
    let difference = a.difference(b)
    let symmetric = a.symmetricDifference(b)

    for i in union:
      check ah.contains(i) or bh.contains(i)

    for i in intersection:
      check ah.contains(i) and bh.contains(i)

    for i in difference:
      check ah.contains(i) and not bh.contains(i)

    for i in symmetric:
      check ah.contains(i) xor bh.contains(i)

    for i in 0..<100:
      check union.contains(i) == (ah.contains(i) or bh.contains(i))
      check intersection.contains(i) == (ah.contains(i) and bh.contains(i))
      check difference.contains(i) == (ah.contains(i) and not bh.contains(i))
      check symmetric.contains(i) == (ah.contains(i) xor bh.contains(i))


suite "PSet Empty Sets":
  test "empty set contains nothing":
    let s = initPSet[string]()

    check s.len == 0
    check not s.contains("a")
    check not s.contains("")

  test "empty set iterator yields nothing":
    let s = initPSet[int]()

    var count = 0
    for _ in s:
      inc count

    check count == 0

  test "empty set equality":
    let a = initPSet[int]()
    let b = initPSet[int]()

    check a == b

  test "empty set hash":
    let a = initPSet[int]()
    let b = initPSet[int]()

    check hash(a) == hash(b)

  test "empty set is subset of every set":
    let empty = initPSet[int]()
    var s = initPSet[int]()

    s = s.incl(1).incl(2).incl(3)

    check empty.subset(s)
    check not s.subset(empty)

  test "empty set is not proper subset of itself":
    let empty = initPSet[int]()

    check not empty.properSubset(empty)

  test "empty sets are disjoint":
    let a = initPSet[int]()
    let b = initPSet[int]()

    check a.disjoint(b)

  test "empty set union is correct":
    let empty = initPSet[int]()
    var s = initPSet[int]()

    s = s.incl(1).incl(2)

    check empty.union(s) == s
    check s.union(empty) == s

  test "empty set intersection is correct":
    let empty = initPSet[int]()
    var s = initPSet[int]()

    s = s.incl(1).incl(2)

    check empty.intersection(s).len == 0
    check s.intersection(empty).len == 0

  test "empty set difference is correct":
    let empty = initPSet[int]()
    var s = initPSet[int]()

    s = s.incl(1).incl(2)

    check empty.difference(s).len == 0
    check s.difference(empty) == s

  test "empty set symmetric difference is correct":
    let empty = initPSet[int]()
    var s = initPSet[int]()

    s = s.incl(1).incl(2)

    check empty.symmetricDifference(s) == s
    check s.symmetricDifference(empty) == s

  test "pop on empty set raises KeyError":
    let empty = initPSet[int]()

    expect KeyError:
      discard empty.pop()

  test "excl on empty set remains empty":
    let empty = initPSet[int]()
    check empty.excl(42).len == 0

  test "map on empty set remains empty":
    let empty = initPSet[int]()
    let mapped = empty.map(proc(x: int): string = $x)

    check mapped.len == 0

  test "empty set string representation":
    let empty = initPSet[int]()
    check $empty == "{}"

suite "TCO tests":
  test "factorial":
    func factorial(n: uint64, acc: uint64 = 1'u64): uint64 {.tco.} =
      if n == 0: halt(acc)
      else: rec(n-1, n*acc)

    func factorial_non_tail(n: uint64): uint64 =
      if n == 0: return 1
      else: return n*factorial_non_tail(n-1)
    
    for i in 0..<40:
      check factorial(i.uint64) == factorial_non_tail(i.uint64)

  test "mixed recursion fibonnaci":
    func fibb(n: uint64, acc: uint64 = 0'u64): uint64 {.tco.} =
      if n <= 1: halt(acc+1)
      else:
        let lower = fibb(n-2)
        rec(n-1, acc+lower)

    func fibb_non_tail(n: uint64): uint64 =
      if n <= 1: return 1
      else:
        return fibb_non_tail(n-1)+fibb_non_tail(n-2)

    for i in 0..<30:
        check fibb(i.uint64) == fibb_non_tail(i.uint64)

