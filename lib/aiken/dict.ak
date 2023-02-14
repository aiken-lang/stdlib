//// A module for working with bytearray dictionnaries.
////
//// These dictionnaries are fundamentally ordered lists of key-value pairs,
//// which preserve some invariants. In particular, each key is only present
//// once in the dictionnary.

use aiken/bytearray

/// An opaque `Dict`. The type is opaque because the module maintains some
/// invariant, namely: there's only one occurence of a given key in the dictionnary.
///
/// Note that the `key` parameter is a phantom-type, and only present as a
/// means of documentation. Keys are always `ByteArray`, but can be given
/// meaningful names.
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

/// Remove a key-value pair from the dictionnary. If the key is not found, no changes are made.
///
/// ```aiken
/// dict.new()
/// |> dict.insert(key: 14, value: 42, int.compare)
/// |> dict.delete(key: 14)
/// |> dict.get(14)
/// // None
/// ```
pub fn delete(self: Dict<key, value>, key: key) -> Dict<key, value> {
  Dict { inner: do_delete(self.inner, key) }
}

fn do_delete(self: List<(key, value)>, key k: key) -> List<(key, value)> {
  when self is {
    [] -> []
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
    [] -> []
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

/// Finds a value in the dictionnary, and returns the first key found to have that value.
///
/// ```aiken
/// dict.new()
/// |> dict.insert(key: foo, value: 42, bytearray.compare)
/// |> dict.insert(key: bar, value: 14, bytearray.compare)
/// |> dict.find(42)
/// // Some(foo)
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

/// Fold over the key-value pairs in a dictionnary.
pub fn fold(
  self: Dict<key, value>,
  with: fn(key, value, result) -> result,
  zero: result,
) -> result {
  do_fold(self.inner, with, zero)
}

fn do_fold(
  self: List<(key, value)>,
  with: fn(key, value, result) -> result,
  zero: result,
) -> result {
  when self is {
    [] -> zero
    [(k, v), ..rest] -> with(k, v, do_fold(rest, with, zero))
  }
}

test fold_2() {
  fold(fixture_1(), with: fn(_, v, total) { v + total }, zero: 0) == 56
}

test fold_1() {
  fold(new(), fn(_, _, _) { 42 }, 14) == 14
}

/// Construct a dictionnary from a list of key-value pairs. Note that when a key is present
/// multiple times, the first occurence prevails.
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
    [] -> []
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

/// Get a value in the dict by its key.
///
/// ```aiken
/// dict.new()
/// |> dict.insert(key: foo, value: "Aiken", bytearray.compare)
/// |> dict.get(key: foo)
/// // Some("Aiken")
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

/// Check if a key exists in the dictionnary.
///
/// ```aiken
/// dict.new()
/// |> dict.insert(key: foo, value: "Aiken", bytearray.compare)
/// |> dict.has_key(foo)
/// // True
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

/// Insert a value in the dictionnary at a given key key. If the key already exists, its value is **overridden**.
///
/// ```aiken
/// dict.new()
/// |> dict.insert(key: foo, value: "Foo", bytearray.compare)
/// |> dict.insert(key: foo, value: "Aiken", bytearray.compare)
/// |> dict.to_list()
/// // [(foo, "Aiken")]
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
    [] -> [(k, v)]
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

/// Efficiently checks whether a dictionnary is empty.
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
/// dict.new()
/// |> dict.insert(foo, 14, bytearray.compare)
/// |> dict.insert(bar, 42, bytearray.compare)
/// |> dict.insert(foo, 1337, bytearray.compare)
/// |> dict.keys()
/// // [foo, bar]
/// ```
pub fn keys(self: Dict<key, value>) -> List<key> {
  do_keys(self.inner)
}

fn do_keys(self: List<(key, value)>) -> List<key> {
  when self is {
    [] -> []
    [(k, _), ..rest] -> [k, ..do_keys(rest)]
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
/// pub fn celebrate_birthday(self: Dict<ByteArray, Int>, key: ByteArray) {
///   dict.map(self, with: fn(_key, value) { value + 1 })
/// }
/// ```
pub fn map(self: Dict<key, a>, with: fn(key, a) -> b) -> Dict<key, b> {
  Dict { inner: do_map(self.inner, with) }
}

fn do_map(self: List<(key, a)>, with: fn(key, a) -> b) -> List<(key, b)> {
  when self is {
    [] -> []
    [(k, v), ..rest] -> [(k, with(k, v)), ..do_map(rest, with)]
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

/// Get the inner list holding the dictionnary data.
pub fn to_list(self: Dict<key, value>) -> List<(key, value)> {
  self.inner
}

test to_list_1() {
  to_list(new()) == []
}

test to_list_2() {
  to_list(fixture_1()) == [(bar, 14), (foo, 42)]
}

/// Return the number of key-value pairs in the dictionnary.
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

/// Combine two dictionnaries. If the same key exist in both the left and
/// right dictionnary, values from the left are preferred (i.e. left-biaised).
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
/// in both dictionnaries.
///
/// When passing `None`, the value is removed and not present in the union.
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
    [] -> [(k, v)]
    [(k2, v2), ..rest] ->
      if compare(k, k2) == Less {
        [(k, v), ..self]
      } else {
        if k == k2 {
          when with(k, v, v2) is {
            Some(combined) -> [(k, combined), ..rest]
            None -> rest
          }
        } else {
          [(k2, v2), ..do_insert_with(rest, k, v, with, compare)]
        }
      }
  }
}

// TODO: acceptance_test 035
//
// test union_with_1() {
//   let left =
//     new()
//     |> insert(foo, 14)
//   let right =
//     new()
//     |> insert(bar, 42)
//     |> insert(foo, 1337)
//   union_with(left, right, with: fn(_, l, r) { Some(l + r) }) == from_list(
//   [(foo, 1351), (bar, 42)])
//
// }

/// Combine two dictionnaries using the provided strategy for combining values when the same
/// key is found in both dictionnaries.
/// Extract all the values present in a given `Dict`.
///
/// ```aiken
/// use aiken.dict
///
/// dict.new()
/// |> dict.insert(foo, 14, bytearray.compare)
/// |> dict.insert(bar, 42, bytearray.compare)
/// |> dict.insert(foo, 1337, bytearray.compare)
/// |> dict.values()
/// // [42, 1337]
/// ```
pub fn values(self: Dict<key, value>) -> List<value> {
  do_values(self.inner)
}

fn do_values(self: List<(key, value)>) -> List<value> {
  when self is {
    [] -> []
    [(_, v), ..rest] -> [v, ..do_values(rest)]
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
