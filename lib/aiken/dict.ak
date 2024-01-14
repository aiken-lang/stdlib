//// A module for working with bytearray dictionaries.
////
//// These dictionaries are fundamentally ordered lists of key-value pairs,
//// which preserve some invariants. In particular, each key is only present
//// once in the dictionary.

use aiken/builtin

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
  inner: List<(ByteArray, value)>,
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
    |> insert(foo, 42)
    |> insert(bar, 14)
}

/// Remove a key-value pair from the dictionary. If the key is not found, no changes are made.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.delete(key: "a")
///     |> dict.to_list()
///
/// result == [("b", 200)]
/// ```
pub fn delete(self: Dict<key, value>, key: ByteArray) -> Dict<key, value> {
  Dict { inner: do_delete(self.inner, key) }
}

fn do_delete(
  self: List<(ByteArray, value)>,
  key k: ByteArray,
) -> List<(ByteArray, value)> {
  when self is {
    [] ->
      []
    [(k2, v2), ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          rest
        } else {
          self
        }
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
      |> insert(foo, 14)
  delete(m, foo) == new()
}

test delete_3() {
  let m =
    new()
      |> insert(foo, 14)
  delete(m, bar) == m
}

test delete_4() {
  let m =
    new()
      |> insert(foo, 14)
      |> insert(bar, 14)
  !has_key(delete(m, foo), foo)
}

test delete_5() {
  let m =
    new()
      |> insert(foo, 14)
      |> insert(bar, 14)
  has_key(delete(m, bar), foo)
}

test delete_6() {
  let m =
    new()
      |> insert("aaa", 1)
      |> insert("bbb", 2)
      |> insert("ccc", 3)
      |> insert("ddd", 4)
      |> insert("eee", 5)
      |> insert("fff", 6)
      |> insert("ggg", 7)
      |> insert("hhh", 8)
      |> insert("iii", 9)
      |> insert("jjj", 10)

  delete(m, "bcd") == m
}

/// Keep only the key-value pairs that pass the given predicate.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.insert(key: "c", value: 300)
///     |> dict.filter(fn(k, _v) { k != "a" })
///     |> dict.to_list()
///
/// result == [("b", 200), ("c", 300)]
/// ```
pub fn filter(
  self: Dict<key, value>,
  with: fn(ByteArray, value) -> Bool,
) -> Dict<key, value> {
  Dict { inner: do_filter(self.inner, with) }
}

fn do_filter(
  self: List<(ByteArray, value)>,
  with: fn(ByteArray, value) -> Bool,
) -> List<(ByteArray, value)> {
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
      |> insert(foo, 42)
  filter(fixture_1(), fn(_, v) { v > 14 }) == expected
}

test filter_3() {
  let expected =
    new()
      |> insert(bar, 14)
  filter(fixture_1(), fn(k, _) { k == bar }) == expected
}

/// Finds a value in the dictionary, and returns the first key found to have that value.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: 42)
///     |> dict.insert(key: "b", value: 14)
///     |> dict.insert(key: "c", value: 42)
///     |> dict.find(42)
///
/// result == Some("c")
/// ```
pub fn find(self: Dict<key, value>, value v: value) -> Option<ByteArray> {
  do_find(self.inner, v)
}

fn do_find(self: List<(ByteArray, value)>, value v: value) -> Option<ByteArray> {
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
      |> insert(foo, 14),
    14,
  ) == Some(foo)
}

test find_3() {
  find(
    new()
      |> insert(foo, 14),
    42,
  ) == None
}

test find_4() {
  find(
    new()
      |> insert(foo, 14)
      |> insert(bar, 42)
      |> insert(baz, 14),
    14,
  ) == Some(baz)
}

/// Fold over the key-value pairs in a dictionary. The fold direction follows keys
/// in ascending order and is done from right-to-left.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.insert(key: "c", value: 300)
///     |> dict.foldr(0, fn(_k, v, r) { v + r })
///
/// result == 600
/// ```
pub fn foldr(
  self: Dict<key, value>,
  zero: result,
  with: fn(ByteArray, value, result) -> result,
) -> result {
  do_foldr(self.inner, zero, with)
}

fn do_foldr(
  self: List<(ByteArray, value)>,
  zero: result,
  with: fn(ByteArray, value, result) -> result,
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
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.insert(key: "c", value: 300)
///     |> dict.foldl(0, fn(_k, v, r) { v + r })
///
/// result == 600
/// ```
pub fn foldl(
  self: Dict<key, value>,
  zero: result,
  with: fn(ByteArray, value, result) -> result,
) -> result {
  do_foldl(self.inner, zero, with)
}

fn do_foldl(
  self: List<(ByteArray, value)>,
  zero: result,
  with: fn(ByteArray, value, result) -> result,
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
/// let list = [("a", 100), ("c", 300), ("b", 200)]
///
/// let result =
///   dict.from_list(list)
///     |> dict.to_list()
///
/// result == [("a", 100), ("b", 200), ("c", 300)]
/// ```
pub fn from_list(self: List<(ByteArray, value)>) -> Dict<key, value> {
  Dict { inner: do_from_list(self) }
}

fn do_from_list(xs: List<(ByteArray, value)>) -> List<(ByteArray, value)> {
  when xs is {
    [] ->
      []
    [(k, v), ..rest] -> do_insert(do_from_list(rest), k, v)
  }
}

test from_list_1() {
  from_list([]) == new()
}

test from_list_2() {
  from_list([(foo, 42), (bar, 14)]) == from_list([(bar, 14), (foo, 42)])
}

test from_list_3() {
  from_list([(foo, 42), (bar, 14)]) == fixture_1()
}

test from_list_4() {
  from_list([(foo, 42), (bar, 14), (foo, 1337)]) == fixture_1()
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
    )

  size(dict) == 16
}

/// Like ['from_list'](from_list), but from an already sorted list by ascending
/// keys. This function fails (i.e. halt the program execution) if the list isn't
/// sorted.
///
/// ```aiken
/// let list = [("a", 100), ("b", 200), ("c", 300)]
///
/// let result =
///   dict.from_ascending_list(list)
///     |> dict.to_list()
///
/// result == [("a", 100), ("b", 200), ("c", 300)]
/// ```
///
/// This is meant to be used to turn a list constructed off-chain into a `Dict`
/// which has taken care of maintaining interval invariants. This function still
/// performs a sanity check on all keys to avoid silly mistakes. It is, however,
/// considerably faster than ['from_list'](from_list)
pub fn from_ascending_list(xs: List<(ByteArray, value)>) -> Dict<key, value> {
  let Void = check_ascending_list(xs)
  Dict { inner: xs }
}

fn check_ascending_list(xs: List<(ByteArray, value)>) {
  when xs is {
    [] -> Void
    [_] -> Void
    [(x0, _), (x1, _) as e, ..rest] ->
      if builtin.less_than_bytearray(x0, x1) {
        check_ascending_list([e, ..rest])
      } else {
        fail @"keys in associative list aren't in ascending order"
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
    )

  size(dict) == 16
}

/// Get a value in the dict by its key.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: "Aiken")
///     |> dict.get(key: "a")
///
///  result == Some("Aiken")
/// ```
pub fn get(self: Dict<key, value>, key: ByteArray) -> Option<value> {
  do_get(self.inner, key)
}

fn do_get(self: List<(ByteArray, value)>, key k: ByteArray) -> Option<value> {
  when self is {
    [] -> None
    [(k2, v), ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          Some(v)
        } else {
          None
        }
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
      |> insert(foo, "Aiken")
      |> insert(bar, "awesome")
  get(m, key: foo) == Some("Aiken")
}

test get_3() {
  let m =
    new()
      |> insert(foo, "Aiken")
      |> insert(bar, "awesome")
  get(m, key: baz) == None
}

test get_4() {
  let m =
    new()
      |> insert("aaa", "1")
      |> insert("bbb", "2")
      |> insert("ccc", "3")
      |> insert("ddd", "4")
      |> insert("eee", "5")
      |> insert("fff", "6")
      |> insert("ggg", "7")
      |> insert("hhh", "8")
      |> insert("iii", "9")
      |> insert("jjj", "10")

  get(m, "bcd") == None
}

test get_5() {
  let m =
    new()
      |> insert("aaa", "1")
      |> insert("bbb", "2")
      |> insert("ccc", "3")
      |> insert("ddd", "4")
      |> insert("eee", "5")
      |> insert("fff", "6")
      |> insert("ggg", "7")
      |> insert("hhh", "8")
      |> insert("iii", "9")
      |> insert("jjj", "10")

  get(m, "kkk") == None
}

/// Check if a key exists in the dictionary.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: "Aiken")
///     |> dict.has_key("a")
///
/// result == True
/// ```
pub fn has_key(self: Dict<key, value>, key k: ByteArray) -> Bool {
  do_has_key(self.inner, k)
}

fn do_has_key(self: List<(ByteArray, value)>, key k: ByteArray) -> Bool {
  when self is {
    [] -> False
    [(k2, _), ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        k == k2
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
      |> insert(foo, 14),
    foo,
  )
}

test has_key_3() {
  !has_key(
    new()
      |> insert(foo, 14),
    bar,
  )
}

test has_key_4() {
  has_key(
    new()
      |> insert(foo, 14)
      |> insert(bar, 42),
    bar,
  )
}

/// Insert a value in the dictionary at a given key. If the key already exists, its value is **overridden**. If you need ways to combine keys together, use (`insert_with`)[#insert_with].
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert(key: "a", value: 1)
///     |> dict.insert(key: "b", value: 2)
///     |> dict.insert(key: "a", value: 3)
///     |> dict.to_list()
///
/// result == [("a", 3), ("b", 2)]
/// ```
pub fn insert(
  self: Dict<key, value>,
  key k: ByteArray,
  value v: value,
) -> Dict<key, value> {
  Dict { inner: do_insert(self.inner, k, v) }
}

fn do_insert(
  self: List<(ByteArray, value)>,
  key k: ByteArray,
  value v: value,
) -> List<(ByteArray, value)> {
  when self is {
    [] ->
      [(k, v)]
    [(k2, v2), ..rest] ->
      if builtin.less_than_bytearray(k, k2) {
        [(k, v), ..self]
      } else {
        if k == k2 {
          [(k, v), ..rest]
        } else {
          [(k2, v2), ..do_insert(rest, k, v)]
        }
      }
  }
}

test insert_1() {
  let m1 =
    new()
      |> insert(foo, 42)
  let m2 =
    new()
      |> insert(foo, 14)
  insert(m1, foo, 14) == m2
}

test insert_2() {
  let m1 =
    new()
      |> insert(foo, 42)
  let m2 =
    new()
      |> insert(bar, 14)
  insert(m1, bar, 14) == insert(m2, foo, 42)
}

/// Insert a value in the dictionary at a given key. When the key already exist, the provided
/// merge function is called.
///
/// ```aiken
/// let sum =
///   fn (_k, a, b) { Some(a + b) }
///
/// let result =
///   dict.new()
///     |> dict.insert_with(key: "a", value: 1, with: sum)
///     |> dict.insert_with(key: "b", value: 2, with: sum)
///     |> dict.insert_with(key: "a", value: 3, with: sum)
///     |> dict.to_list()
///
/// result == [("a", 4), ("b", 2)]
/// ```
pub fn insert_with(
  self: Dict<key, value>,
  key k: ByteArray,
  value v: value,
  with: fn(ByteArray, value, value) -> Option<value>,
) -> Dict<key, value> {
  Dict {
    inner: do_insert_with(self.inner, k, v, fn(k, v1, v2) { with(k, v2, v1) }),
  }
}

test insert_with_1() {
  let sum =
    fn(_k, a, b) { Some(a + b) }

  let result =
    new()
      |> insert_with(key: "foo", value: 1, with: sum)
      |> insert_with(key: "bar", value: 2, with: sum)
      |> to_list()

  result == [("bar", 2), ("foo", 1)]
}

test insert_with_2() {
  let sum =
    fn(_k, a, b) { Some(a + b) }

  let result =
    new()
      |> insert_with(key: "foo", value: 1, with: sum)
      |> insert_with(key: "bar", value: 2, with: sum)
      |> insert_with(key: "foo", value: 3, with: sum)
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
      |> insert_with(key: "foo", value: 1, with: with)
      |> insert_with(key: "bar", value: 2, with: with)
      |> insert_with(key: "foo", value: 3, with: with)
      |> insert_with(key: "bar", value: 4, with: with)
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
/// let result =
///   dict.new()
///     |> dict.insert("a", 14)
///     |> dict.insert("b", 42)
///     |> dict.insert("a", 1337)
///     |> dict.keys()
///
/// result == ["a", "b"]
/// ```
pub fn keys(self: Dict<key, value>) -> List<ByteArray> {
  do_keys(self.inner)
}

fn do_keys(self: List<(ByteArray, value)>) -> List<ByteArray> {
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
      |> insert(foo, 0)
      |> insert(bar, 0),
  ) == [bar, foo]
}

/// Apply a function to all key-value pairs in a map.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert("a", 100)
///     |> dict.insert("b", 200)
///     |> dict.insert("c", 300)
///     |> dict.map(fn(_k, v) { v * 2 })
///     |> dict.to_list()
///
///  result == [("a", 200), ("b", 400), ("c", 600)]
/// ```
pub fn map(self: Dict<key, a>, with: fn(ByteArray, a) -> b) -> Dict<key, b> {
  Dict { inner: do_map(self.inner, with) }
}

fn do_map(
  self: List<(ByteArray, a)>,
  with: fn(ByteArray, a) -> b,
) -> List<(ByteArray, b)> {
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
/// let result =
///   dict.new()
///     |> dict.insert("a", 100)
///     |> dict.insert("b", 200)
///     |> dict.insert("c", 300)
///     |> dict.to_list()
///
/// result == [("a", 100), ("b", 200), ("c", 300)]
/// ```
pub fn to_list(self: Dict<key, value>) -> List<(ByteArray, value)> {
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
/// let result =
///   dict.new()
///     |> dict.insert("a", 100)
///     |> dict.insert("b", 200)
///     |> dict.insert("c", 300)
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
      |> insert(foo, 14),
  ) == 1
}

test size_3() {
  size(
    new()
      |> insert(foo, 14)
      |> insert(bar, 42),
  ) == 2
}

/// Combine two dictionaries. If the same key exist in both the left and
/// right dictionary, values from the left are preferred (i.e. left-biaised).
///
/// ```aiken
/// let left_dict = dict.from_list([("a", 100), ("b", 200)])
/// let right_dict = dict.from_list([("a", 150), ("c", 300)])
///
/// let result =
///   dict.union(left_dict, right_dict) |> dict.to_list()
///
/// result == [("a", 100), ("b", 200), ("c", 300)]
/// ```
pub fn union(
  left: Dict<key, value>,
  right: Dict<key, value>,
) -> Dict<key, value> {
  Dict { inner: do_union(left.inner, right.inner) }
}

fn do_union(
  left: List<(ByteArray, value)>,
  right: List<(ByteArray, value)>,
) -> List<(ByteArray, value)> {
  when left is {
    [] -> right
    [(k, v), ..rest] -> do_union(rest, do_insert(right, k, v))
  }
}

test union_1() {
  union(fixture_1(), new()) == fixture_1()
}

test union_2() {
  union(new(), fixture_1()) == fixture_1()
}

test union_3() {
  let left =
    new()
      |> insert(foo, 14)
  let right =
    new()
      |> insert(bar, 42)
      |> insert(baz, 1337)
  union(left, right) == from_list([(foo, 14), (baz, 1337), (bar, 42)])
}

test union_4() {
  let left =
    new()
      |> insert(foo, 14)
  let right =
    new()
      |> insert(bar, 42)
      |> insert(foo, 1337)
  union(left, right) == from_list([(foo, 14), (bar, 42)])
}

/// Like [`union`](#union) but allows specifying the behavior to adopt when a key is present
/// in both dictionaries. The first value received correspond to the value in the left
/// dictionnary, whereas the second argument corresponds to the value in the right dictionnary.
///
/// When passing `None`, the value is removed and not present in the union.
///
/// ```aiken
/// let left_dict = dict.from_list([("a", 100), ("b", 200)])
/// let right_dict = dict.from_list([("a", 150), ("c", 300)])
///
/// let result =
///   dict.union_with(
///     left_dict,
///     right_dict,
///     fn(_k, v1, v2) { Some(v1 + v2) },
///   )
///     |> dict.to_list()
///
/// result == [("a", 250), ("b", 200), ("c", 300)]
/// ```
pub fn union_with(
  left: Dict<key, value>,
  right: Dict<key, value>,
  with: fn(ByteArray, value, value) -> Option<value>,
) -> Dict<key, value> {
  Dict { inner: do_union_with(left.inner, right.inner, with) }
}

fn do_union_with(
  left: List<(ByteArray, value)>,
  right: List<(ByteArray, value)>,
  with: fn(ByteArray, value, value) -> Option<value>,
) -> List<(ByteArray, value)> {
  when left is {
    [] -> right
    [(k, v), ..rest] ->
      do_union_with(rest, do_insert_with(right, k, v, with), with)
  }
}

fn do_insert_with(
  self: List<(ByteArray, value)>,
  key k: ByteArray,
  value v: value,
  with: fn(ByteArray, value, value) -> Option<value>,
) -> List<(ByteArray, value)> {
  when self is {
    [] ->
      [(k, v)]
    [(k2, v2), ..rest] ->
      if builtin.less_than_bytearray(k, k2) {
        [(k, v), ..self]
      } else {
        if k == k2 {
          when with(k, v, v2) is {
            Some(combined) ->
              [(k, combined), ..rest]
            None -> rest
          }
        } else {
          [(k2, v2), ..do_insert_with(rest, k, v, with)]
        }
      }
  }
}

test union_with_1() {
  let left =
    new()
      |> insert(foo, 14)

  let right =
    new()
      |> insert(bar, 42)
      |> insert(foo, 1337)

  let result = union_with(left, right, with: fn(_, l, r) { Some(l + r) })

  result == from_list([(foo, 1351), (bar, 42)])
}

/// Extract all the values present in a given `Dict`.
///
/// ```aiken
/// let result =
///   dict.new()
///     |> dict.insert("a", 14)
///     |> dict.insert("b", 42)
///     |> dict.insert("c", 1337)
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
      |> insert(foo, 3)
      |> insert(bar, 4),
  ) == [4, 3]
}
