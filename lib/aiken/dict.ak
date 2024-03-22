//// A module for working with bytearray dictionaries.
////
//// These dictionaries are fundamentally ordered lists of key-value pairs,
//// which preserve some invariants. In particular, each key is only present
//// once in the dictionary.

use aiken/bytearray

/// An opaque `Dict`. The type is opaque because the module maintains some
/// invariant, namely: there's only one occurrence of a given key in the dictionary.
///
/// Note that the `key` parameter is a phantom-type, and only present as a
/// means of documentation. Keys can be any type, yet will need to comparable
/// to use functions like `insert`.
///
/// See for example:
///
/// ```aiken
/// pub type Value =
///   Dict<PolicyId, Dict<AssetName, Int>>
/// ```
pub opaque type Dict<key, value> {
  inner: List<(key, value)>,
}

/// Create a new map
/// ```aiken
/// dict.to_list(dict.new()) == []
/// ```
pub fn new() -> Dict<key, value> {
  Dict { inner: [] }
}

const foo = #"666f6f"

const bar = #"626172"

const baz = #"62617a"

fn fixture_1() {
  new()
    |> insert(foo, 42, bytearray.compare)
    |> insert(bar, 14, bytearray.compare)
}

/// Remove a key-value pair from the dictionary. If the key is not found, no changes are made.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(key: 1, value: 100, compare: int.compare)
///     |> dict.insert(key: 2, value: 200, compare: int.compare)
///     |> dict.delete(key: 1)
///     |> dict.to_list()
///
/// result == [(2, 200)]
/// ```
pub fn delete(self: Dict<key, value>, key: key) -> Dict<key, value> {
  Dict { inner: do_delete(self.inner, key) }
}

fn do_delete(self: List<(key, value)>, key k: key) -> List<(key, value)> {
  when self is {
    [] ->
      []
    [(k2, v2), ..rest] ->
      if k == k2 {
        rest
      } else {
        [(k2, v2), ..do_delete(rest, k)]
      }
  }
}

test delete_1() {
  delete(new(), foo) == new()
}

test delete_2() {
  let m =
    new()
      |> insert(foo, 14, bytearray.compare)
  delete(m, foo) == new()
}

test delete_3() {
  let m =
    new()
      |> insert(foo, 14, bytearray.compare)
  delete(m, bar) == m
}

test delete_4() {
  let m =
    new()
      |> insert(foo, 14, bytearray.compare)
      |> insert(bar, 14, bytearray.compare)
  !has_key(delete(m, foo), foo)
}

test delete_5() {
  let m =
    new()
      |> insert(foo, 14, bytearray.compare)
      |> insert(bar, 14, bytearray.compare)
  has_key(delete(m, bar), foo)
}

/// Keep only the key-value pairs that pass the given predicate.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(key: 1, value: 100, compare: int.compare)
///     |> dict.insert(key: 2, value: 200, compare: int.compare)
///     |> dict.insert(key: 3, value: 300, compare: int.compare)
///     |> dict.filter(fn(k, _v) { k > 1 })
///     |> dict.to_list()
///
/// result == [(2, 200), (3, 300)]
/// ```
pub fn filter(
  self: Dict<key, value>,
  with: fn(key, value) -> Bool,
) -> Dict<key, value> {
  Dict { inner: do_filter(self.inner, with) }
}

fn do_filter(
  self: List<(key, value)>,
  with: fn(key, value) -> Bool,
) -> List<(key, value)> {
  when self is {
    [] ->
      []
    [(k, v), ..rest] ->
      if with(k, v) {
        [(k, v), ..do_filter(rest, with)]
      } else {
        do_filter(rest, with)
      }
  }
}

test filter_1() {
  filter(new(), fn(_, _) { True }) == new()
}

test filter_2() {
  let expected =
    new()
      |> insert(foo, 42, bytearray.compare)
  filter(fixture_1(), fn(_, v) { v > 14 }) == expected
}

test filter_3() {
  let expected =
    new()
      |> insert(bar, 14, bytearray.compare)
  filter(fixture_1(), fn(k, _) { k == bar }) == expected
}

/// Finds a value in the dictionary, and returns the first key found to have that value.
///
/// ```aiken
/// use aiken/bytearray
///
/// let foo: ByteArray = #"00"
/// let bar: ByteArray = #"11"
/// let baz: ByteArray = #"22"
///
/// let result =
///   dict.new()
///     |> dict.insert(key: foo, value: 42, compare: bytearray.compare)
///     |> dict.insert(key: bar, value: 14, compare: bytearray.compare)
///     |> dict.insert(key: baz, value: 42, compare: bytearray.compare)
///     |> dict.find(42)
///
/// result == Some(foo)
/// ```
pub fn find(self: Dict<key, value>, value v: value) -> Option<key> {
  do_find(self.inner, v)
}

fn do_find(self: List<(key, value)>, value v: value) -> Option<key> {
  when self is {
    [] -> None
    [(k2, v2), ..rest] ->
      if v == v2 {
        Some(k2)
      } else {
        do_find(rest, v)
      }
  }
}

test find_1() {
  find(new(), foo) == None
}

test find_2() {
  find(
    new()
      |> insert(foo, 14, bytearray.compare),
    14,
  ) == Some(foo)
}

test find_3() {
  find(
    new()
      |> insert(foo, 14, bytearray.compare),
    42,
  ) == None
}

test find_4() {
  find(
    new()
      |> insert(foo, 14, bytearray.compare)
      |> insert(bar, 42, bytearray.compare)
      |> insert(baz, 14, bytearray.compare),
    14,
  ) == Some(baz)
}

/// Fold over the key-value pairs in a dictionary. The fold direction follows keys
/// in ascending order and is done from right-to-left.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(key: 1, value: 100, compare: int.compare)
///     |> dict.insert(key: 2, value: 200, compare: int.compare)
///     |> dict.insert(key: 3, value: 300, compare: int.compare)
///     |> dict.foldr(0, fn(_k, v, r) { v + r })
///
/// result == 600
/// ```
pub fn foldr(
  self: Dict<key, value>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  do_foldr(self.inner, zero, with)
}

fn do_foldr(
  self: List<(key, value)>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [(k, v), ..rest] -> with(k, v, do_foldr(rest, zero, with))
  }
}

test foldr_1() {
  foldr(new(), 14, fn(_, _, _) { 42 }) == 14
}

test foldr_2() {
  foldr(fixture_1(), zero: 0, with: fn(_, v, total) { v + total }) == 56
}

/// Fold over the key-value pairs in a dictionary. The fold direction follows keys
/// in ascending order and is done from left-to-right.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(key: 1, value: 100, compare: int.compare)
///     |> dict.insert(key: 2, value: 200, compare: int.compare)
///     |> dict.insert(key: 3, value: 300, compare: int.compare)
///     |> dict.foldl(0, fn(_k, v, r) { v + r })
///
/// result == 600
/// ```
pub fn foldl(
  self: Dict<key, value>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  do_foldl(self.inner, zero, with)
}

fn do_foldl(
  self: List<(key, value)>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [(k, v), ..rest] -> do_foldl(rest, with(k, v, zero), with)
  }
}

test fold_1() {
  foldl(new(), 14, fn(_, _, _) { 42 }) == 14
}

test fold_2() {
  foldl(fixture_1(), zero: 0, with: fn(_, v, total) { v + total }) == 56
}

/// Construct a dictionary from a list of key-value pairs. Note that when a key is present
/// multiple times, the first occurrence prevails.
///
/// ```aiken
/// use aiken/int
///
/// let list = [(1, 100), (3, 300), (2, 200)]
///
/// let result =
///   dict.from_list(list, int.compare)
///     |> dict.to_list()
///
/// result == [(1, 100), (2, 200), (3, 300)]
/// ```
pub fn from_list(
  self: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
) -> Dict<key, value> {
  Dict { inner: do_from_list(self, compare) }
}

fn do_from_list(
  xs: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
) -> List<(key, value)> {
  when xs is {
    [] ->
      []
    [(k, v), ..rest] -> do_insert(do_from_list(rest, compare), k, v, compare)
  }
}

test from_list_1() {
  from_list([], bytearray.compare) == new()
}

test from_list_2() {
  from_list([(foo, 42), (bar, 14)], bytearray.compare) == from_list(
    [(bar, 14), (foo, 42)],
    bytearray.compare,
  )
}

test from_list_3() {
  from_list([(foo, 42), (bar, 14)], bytearray.compare) == fixture_1()
}

test from_list_4() {
  from_list([(foo, 42), (bar, 14), (foo, 1337)], bytearray.compare) == fixture_1()
}

test bench_from_list() {
  let dict =
    from_list(
      [
        ("bbba", 8),
        ("bbab", 12),
        ("aabb", 13),
        ("aaab", 9),
        ("bbbb", 16),
        ("aaaa", 1),
        ("aaba", 5),
        ("abab", 10),
        ("baba", 7),
        ("baab", 11),
        ("abaa", 2),
        ("baaa", 3),
        ("bbaa", 4),
        ("babb", 15),
        ("abbb", 14),
        ("abba", 6),
      ],
      bytearray.compare,
    )

  size(dict) == 16
}

/// Like ['from_list'](from_list), but from an already sorted list by ascending
/// keys. This function fails (i.e. halt the program execution) if the list isn't
/// sorted.
///
/// ```aiken
/// use aiken/int
///
/// let list = [(1, 100), (2, 200), (3, 300)]
///
/// let result =
///   dict.from_ascending_list(list, int.compare)
///     |> dict.to_list()
///
/// result == [(1, 100), (2, 200), (3, 300)]
/// ```
///
/// This is meant to be used to turn a list constructed off-chain into a `Dict`
/// which has taken care of maintaining interval invariants. This function still
/// performs a sanity check on all keys to avoid silly mistakes. It is, however,
/// considerably faster than ['from_list'](from_list)
pub fn from_ascending_list(
  xs: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
) -> Dict<key, value> {
  let Void = check_ascending_list(xs, compare)
  Dict { inner: xs }
}

fn check_ascending_list(
  xs: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
) {
  when xs is {
    [] -> Void
    [_] -> Void
    [(x0, _), (x1, _) as e, ..rest] ->
      when compare(x0, x1) is {
        Less -> check_ascending_list([e, ..rest], compare)
        _ -> fail @"keys in associative list aren't in ascending order"
      }
  }
}

pub fn from_ascending_list_with(
  xs: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
  value_predicate: fn(value) -> Bool,
) -> Dict<key, value> {
  let Void = check_ascending_list_with(xs, compare, value_predicate)
  Dict { inner: xs }
}

fn check_ascending_list_with(
  xs: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
  value_predicate: fn(value) -> Bool,
) {
  when xs is {
    [] -> Void
    [(_, v)] ->
      if value_predicate(v) {
        Void
      } else {
        fail @"value doesn't satisfy predicate"
      }
    [(x0, v0), (x1, _) as e, ..rest] ->
      when compare(x0, x1) is {
        Less ->
          if value_predicate(v0) {
            check_ascending_list_with([e, ..rest], compare, value_predicate)
          } else {
            fail @"value doesn't satisfy predicate"
          }
        _ -> fail @"keys in associative list aren't in ascending order"
      }
  }
}

test bench_from_ascending_list() {
  let dict =
    from_ascending_list(
      [
        ("aaaa", 1),
        ("aaab", 9),
        ("aaba", 5),
        ("aabb", 13),
        ("abaa", 2),
        ("abab", 10),
        ("abba", 6),
        ("abbb", 14),
        ("baaa", 3),
        ("baab", 11),
        ("baba", 7),
        ("babb", 15),
        ("bbaa", 4),
        ("bbab", 12),
        ("bbba", 8),
        ("bbbb", 16),
      ],
      bytearray.compare,
    )

  size(dict) == 16
}

/// Get a value in the dict by its key.
///
/// ```aiken
/// use aiken/bytearray
///
/// let foo: ByteArray = #"00"
///
/// let result =
///   dict.new()
///     |> dict.insert(key: foo, value: "Aiken", compare: bytearray.compare)
///     |> dict.get(key: foo)
///
///  result == Some("Aiken")
/// ```
pub fn get(self: Dict<key, value>, key: key) -> Option<value> {
  do_get(self.inner, key)
}

fn do_get(self: List<(key, value)>, key k: key) -> Option<value> {
  when self is {
    [] -> None
    [(k2, v), ..rest] ->
      if k == k2 {
        Some(v)
      } else {
        do_get(rest, k)
      }
  }
}

test get_1() {
  get(new(), foo) == None
}

test get_2() {
  let m =
    new()
      |> insert(foo, "Aiken", bytearray.compare)
      |> insert(bar, "awesome", bytearray.compare)
  get(m, key: foo) == Some("Aiken")
}

test get_3() {
  let m =
    new()
      |> insert(foo, "Aiken", bytearray.compare)
      |> insert(bar, "awesome", bytearray.compare)
  get(m, key: baz) == None
}

/// Check if a key exists in the dictionary.
///
/// ```aiken
/// use aiken/bytearray
///
/// let foo: ByteArray = #"00"
///
/// let result =
///   dict.new()
///     |> dict.insert(key: foo, value: "Aiken", compare: bytearray.compare)
///     |> dict.has_key(foo)
///
/// result == True
/// ```
pub fn has_key(self: Dict<key, value>, key k: key) -> Bool {
  do_has_key(self.inner, k)
}

fn do_has_key(self: List<(key, value)>, key k: key) -> Bool {
  when self is {
    [] -> False
    [(k2, _), ..rest] ->
      if k == k2 {
        True
      } else {
        do_has_key(rest, k)
      }
  }
}

test has_key_1() {
  !has_key(new(), foo)
}

test has_key_2() {
  has_key(
    new()
      |> insert(foo, 14, bytearray.compare),
    foo,
  )
}

test has_key_3() {
  !has_key(
    new()
      |> insert(foo, 14, bytearray.compare),
    bar,
  )
}

test has_key_4() {
  has_key(
    new()
      |> insert(foo, 14, bytearray.compare)
      |> insert(bar, 42, bytearray.compare),
    bar,
  )
}

/// Insert a value in the dictionary at a given key. If the key already exists, its value is **overridden**. If you need ways to combine keys together, use (`insert_with`)[#insert_with].
///
/// ```aiken
/// use aiken/bytearray
///
/// let result =
///   dict.new()
///     |> dict.insert(key: "foo", value: 1, compare: bytearray.compare)
///     |> dict.insert(key: "bar", value: 2, compare: bytearray.compare)
///     |> dict.insert(key: "foo", value: 3, compare: bytearray.compare)
///     |> dict.to_list()
///
/// result == [("bar", 2), ("foo", 3)]
/// ```
pub fn insert(
  self: Dict<key, value>,
  key k: key,
  value v: value,
  compare: fn(key, key) -> Ordering,
) -> Dict<key, value> {
  Dict { inner: do_insert(self.inner, k, v, compare) }
}

fn do_insert(
  self: List<(key, value)>,
  key k: key,
  value v: value,
  compare: fn(key, key) -> Ordering,
) -> List<(key, value)> {
  when self is {
    [] ->
      [(k, v)]
    [(k2, v2), ..rest] ->
      if compare(k, k2) == Less {
        [(k, v), ..self]
      } else {
        if k == k2 {
          [(k, v), ..rest]
        } else {
          [(k2, v2), ..do_insert(rest, k, v, compare)]
        }
      }
  }
}

test insert_1() {
  let m1 =
    new()
      |> insert(foo, 42, bytearray.compare)
  let m2 =
    new()
      |> insert(foo, 14, bytearray.compare)
  insert(m1, foo, 14, bytearray.compare) == m2
}

test insert_2() {
  let m1 =
    new()
      |> insert(foo, 42, bytearray.compare)
  let m2 =
    new()
      |> insert(bar, 14, bytearray.compare)
  insert(m1, bar, 14, bytearray.compare) == insert(
    m2,
    foo,
    42,
    bytearray.compare,
  )
}

/// Insert a value in the dictionary at a given key. When the key already exist, the provided
/// merge function is called.
///
/// ```aiken
/// use aiken/bytearray
///
/// let sum =
///   fn (_k, a, b) { Some(a + b) }
///
/// let result =
///   dict.new()
///     |> dict.insert_with(key: "foo", value: 1, with: sum, compare: bytearray.compare)
///     |> dict.insert_with(key: "bar", value: 2, with: sum, compare: bytearray.compare)
///     |> dict.insert_with(key: "foo", value: 3, with: sum, compare: bytearray.compare)
///     |> dict.to_list()
///
/// result == [("bar", 2), ("foo", 4)]
/// ```
pub fn insert_with(
  self: Dict<key, value>,
  key k: key,
  value v: value,
  with: fn(key, value, value) -> Option<value>,
  compare: fn(key, key) -> Ordering,
) -> Dict<key, value> {
  Dict {
    inner: do_insert_with(
      self.inner,
      k,
      v,
      fn(k, v1, v2) { with(k, v2, v1) },
      compare,
    ),
  }
}

test insert_with_1() {
  let sum =
    fn(_k, a, b) { Some(a + b) }

  let result =
    new()
      |> insert_with(key: "foo", value: 1, with: sum, compare: bytearray.compare)
      |> insert_with(key: "bar", value: 2, with: sum, compare: bytearray.compare)
      |> to_list()

  result == [("bar", 2), ("foo", 1)]
}

test insert_with_2() {
  let sum =
    fn(_k, a, b) { Some(a + b) }

  let result =
    new()
      |> insert_with(key: "foo", value: 1, with: sum, compare: bytearray.compare)
      |> insert_with(key: "bar", value: 2, with: sum, compare: bytearray.compare)
      |> insert_with(key: "foo", value: 3, with: sum, compare: bytearray.compare)
      |> to_list()

  result == [("bar", 2), ("foo", 4)]
}

test insert_with_3() {
  let with =
    fn(k, a, _b) {
      if k == "foo" {
        Some(a)
      } else {
        None
      }
    }

  let result =
    new()
      |> insert_with(key: "foo", value: 1, with: with, compare: bytearray.compare)
      |> insert_with(key: "bar", value: 2, with: with, compare: bytearray.compare)
      |> insert_with(key: "foo", value: 3, with: with, compare: bytearray.compare)
      |> insert_with(key: "bar", value: 4, with: with, compare: bytearray.compare)
      |> to_list()

  result == [("foo", 1)]
}

/// Efficiently checks whether a dictionary is empty.
/// ```aiken
/// dict.is_empty(dict.new()) == True
/// ```
pub fn is_empty(self: Dict<key, value>) -> Bool {
  when self.inner is {
    [] -> True
    _ -> False
  }
}

test is_empty_1() {
  is_empty(new())
}

/// Extract all the keys present in a given `Dict`.
///
/// ```aiken
/// use aiken/bytearray
///
/// let foo: ByteArray = #"00"
/// let bar: ByteArray = #"11"
///
/// let result =
///   dict.new()
///     |> dict.insert(foo, 14, bytearray.compare)
///     |> dict.insert(bar, 42, bytearray.compare)
///     |> dict.insert(foo, 1337, bytearray.compare)
///     |> dict.keys()
///
/// result == [foo, bar]
/// ```
pub fn keys(self: Dict<key, value>) -> List<key> {
  do_keys(self.inner)
}

fn do_keys(self: List<(key, value)>) -> List<key> {
  when self is {
    [] ->
      []
    [(k, _), ..rest] ->
      [k, ..do_keys(rest)]
  }
}

test keys_1() {
  keys(new()) == []
}

test keys_2() {
  keys(
    new()
      |> insert(foo, 0, bytearray.compare)
      |> insert(bar, 0, bytearray.compare),
  ) == [bar, foo]
}

/// Apply a function to all key-value pairs in a map.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(1, 100, int.compare)
///     |> dict.insert(2, 200, int.compare)
///     |> dict.insert(3, 300, int.compare)
///     |> dict.map(fn(_k, v) { v * 2 })
///     |> dict.to_list()
///
///  result == [(1, 200), (2, 400), (3, 600)]
/// ```
pub fn map(self: Dict<key, a>, with: fn(key, a) -> b) -> Dict<key, b> {
  Dict { inner: do_map(self.inner, with) }
}

fn do_map(self: List<(key, a)>, with: fn(key, a) -> b) -> List<(key, b)> {
  when self is {
    [] ->
      []
    [(k, v), ..rest] ->
      [(k, with(k, v)), ..do_map(rest, with)]
  }
}

test map_1() {
  let result =
    fixture_1()
      |> map(with: fn(k, _) { k })
  get(result, foo) == Some(foo)
}

test map_2() {
  let result =
    fixture_1()
      |> map(with: fn(_, v) { v + 1 })
  get(result, foo) == Some(43) && size(result) == size(fixture_1())
}

/// Get the inner list holding the dictionary data.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(1, 100, int.compare)
///     |> dict.insert(2, 200, int.compare)
///     |> dict.insert(3, 300, int.compare)
///     |> dict.to_list()
///
/// result == [(1, 100), (2, 200), (3, 300)]
/// ```
pub fn to_list(self: Dict<key, value>) -> List<(key, value)> {
  self.inner
}

test to_list_1() {
  to_list(new()) == []
}

test to_list_2() {
  to_list(fixture_1()) == [(bar, 14), (foo, 42)]
}

/// Return the number of key-value pairs in the dictionary.
///
/// ```aiken
/// use aiken/int
///
/// let result =
///   dict.new()
///     |> dict.insert(1, 100, int.compare)
///     |> dict.insert(2, 200, int.compare)
///     |> dict.insert(3, 300, int.compare)
///     |> dict.size()
///
/// result == 3
/// ```
pub fn size(self: Dict<key, value>) -> Int {
  do_size(self.inner)
}

fn do_size(self: List<(key, value)>) -> Int {
  when self is {
    [] -> 0
    [_, ..rest] -> 1 + do_size(rest)
  }
}

test size_1() {
  size(new()) == 0
}

test size_2() {
  size(
    new()
      |> insert(foo, 14, bytearray.compare),
  ) == 1
}

test size_3() {
  size(
    new()
      |> insert(foo, 14, bytearray.compare)
      |> insert(bar, 42, bytearray.compare),
  ) == 2
}

/// Combine two dictionaries. If the same key exist in both the left and
/// right dictionary, values from the left are preferred (i.e. left-biaised).
///
/// ```aiken
/// use aiken/int
///
/// let left_dict = dict.from_list([(1, 100), (2, 200)], int.compare)
/// let right_dict = dict.from_list([(1, 150), (3, 300)], int.compare)
///
/// let result =
///   dict.union(left_dict, right_dict, int.compare) |> dict.to_list()
///
/// result == [(1, 100), (2, 200), (3, 300)]
/// ```
pub fn union(
  left: Dict<key, value>,
  right: Dict<key, value>,
  compare: fn(key, key) -> Ordering,
) -> Dict<key, value> {
  Dict { inner: do_union(left.inner, right.inner, compare) }
}

fn do_union(
  left: List<(key, value)>,
  right: List<(key, value)>,
  compare: fn(key, key) -> Ordering,
) -> List<(key, value)> {
  when left is {
    [] -> right
    [(k, v), ..rest] -> do_union(rest, do_insert(right, k, v, compare), compare)
  }
}

test union_1() {
  union(fixture_1(), new(), bytearray.compare) == fixture_1()
}

test union_2() {
  union(new(), fixture_1(), bytearray.compare) == fixture_1()
}

test union_3() {
  let left =
    new()
      |> insert(foo, 14, bytearray.compare)
  let right =
    new()
      |> insert(bar, 42, bytearray.compare)
      |> insert(baz, 1337, bytearray.compare)
  union(left, right, bytearray.compare) == from_list(
    [(foo, 14), (baz, 1337), (bar, 42)],
    bytearray.compare,
  )
}

test union_4() {
  let left =
    new()
      |> insert(foo, 14, bytearray.compare)
  let right =
    new()
      |> insert(bar, 42, bytearray.compare)
      |> insert(foo, 1337, bytearray.compare)
  union(left, right, bytearray.compare) == from_list(
    [(foo, 14), (bar, 42)],
    bytearray.compare,
  )
}

/// Like [`union`](#union) but allows specifying the behavior to adopt when a key is present
/// in both dictionaries. The first value received correspond to the value in the left
/// dictionnary, whereas the second argument corresponds to the value in the right dictionnary.
///
/// When passing `None`, the value is removed and not present in the union.
///
/// ```aiken
/// use aiken/int
///
/// let left_dict = dict.from_list([(1, 100), (2, 200)], int.compare)
/// let right_dict = dict.from_list([(1, 150), (3, 300)], int.compare)
///
/// let result =
///   dict.union_with(
///     left_dict,
///     right_dict,
///     fn(_k, v1, v2) { Some(v1 + v2) },
///     int.compare,
///   )
///     |> dict.to_list()
///
/// result == [(1, 250), (2, 200), (3, 300)]
/// ```
pub fn union_with(
  left: Dict<key, value>,
  right: Dict<key, value>,
  with: fn(key, value, value) -> Option<value>,
  compare: fn(key, key) -> Ordering,
) -> Dict<key, value> {
  Dict { inner: do_union_with(left.inner, right.inner, with, compare) }
}

fn do_union_with(
  left: List<(key, value)>,
  right: List<(key, value)>,
  with: fn(key, value, value) -> Option<value>,
  compare: fn(key, key) -> Ordering,
) -> List<(key, value)> {
  when left is {
    [] -> right
    [(k, v), ..rest] ->
      do_union_with(
        rest,
        do_insert_with(right, k, v, with, compare),
        with,
        compare,
      )
  }
}

fn do_insert_with(
  self: List<(key, value)>,
  key k: key,
  value v: value,
  with: fn(key, value, value) -> Option<value>,
  compare: fn(key, key) -> Ordering,
) -> List<(key, value)> {
  when self is {
    [] ->
      [(k, v)]
    [(k2, v2), ..rest] ->
      if compare(k, k2) == Less {
        [(k, v), ..self]
      } else {
        if k == k2 {
          when with(k, v, v2) is {
            Some(combined) ->
              [(k, combined), ..rest]
            None -> rest
          }
        } else {
          [(k2, v2), ..do_insert_with(rest, k, v, with, compare)]
        }
      }
  }
}

test union_with_1() {
  let left =
    new()
      |> insert(foo, 14, bytearray.compare)

  let right =
    new()
      |> insert(bar, 42, bytearray.compare)
      |> insert(foo, 1337, bytearray.compare)

  let result =
    union_with(
      left,
      right,
      with: fn(_, l, r) { Some(l + r) },
      compare: bytearray.compare,
    )

  result == from_list([(foo, 1351), (bar, 42)], bytearray.compare)
}

/// Extract all the values present in a given `Dict`.
///
/// ```aiken
/// use aiken/bytearray
///
/// let foo: ByteArray = #"00"
/// let bar: ByteArray = #"11"
///
/// let result =
///   dict.new()
///     |> dict.insert(foo, 14, bytearray.compare)
///     |> dict.insert(bar, 42, bytearray.compare)
///     |> dict.insert(foo, 1337, bytearray.compare)
///     |> dict.values()
///
/// result == [1337, 42]
/// ```
pub fn values(self: Dict<key, value>) -> List<value> {
  do_values(self.inner)
}

fn do_values(self: List<(key, value)>) -> List<value> {
  when self is {
    [] ->
      []
    [(_, v), ..rest] ->
      [v, ..do_values(rest)]
  }
}

test values_1() {
  values(new()) == []
}

test values_2() {
  values(
    new()
      |> insert(foo, 3, bytearray.compare)
      |> insert(bar, 4, bytearray.compare),
  ) == [4, 3]
}
