//// A module for working with bytearray dictionaries.
////
////
//// > [!IMPORTANT]
//// >
//// > Dictionaries are **ordered sets** of key-value pairs, which thus
//// > preserve some invariants. Specifically, each key is only present once in
//// > the dictionary and all keys are stored in ascending lexicographic order.
//// >
//// > These invariants allow for more optimized functions to operate on `Dict`,
//// > but as a trade-offs, prevent `Dict` from being serializable. To recover a `Dict`
//// > from an unknown `Data`, you must first recover an `Pairs<k, v>` and use
//// > [`dict.from_ascending_list`](#from_ascending_list).

use aiken/builtin
use aiken/collection/dict/strategy.{InsertStrategy, UnionStrategy}
use aiken/collection/pairs

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
  inner: Pairs<ByteArray, value>,
}

// ## Constructing

/// An empty dictionary.
/// ```aiken
/// dict.to_pairs(dict.empty) == []
/// ```
pub const empty: Dict<key, value> = Dict { inner: [] }

/// Like ['from_pairs'](#from_pairs), but from an already sorted list by ascending
/// keys. This function fails (i.e. halts the program execution) if the list isn't
/// sorted.
///
/// ```aiken
/// let pairs = [Pair("a", 100), Pair("b", 200), Pair("c", 300)]
///
/// let result =
///   dict.from_ascending_pairs(pairs)
///     |> dict.to_pairs()
///
/// result == [Pair("a", 100), Pair("b", 200), Pair("c", 300)]
/// ```
///
/// This is meant to be used to turn a list constructed off-chain into a `Dict`
/// which has taken care of maintaining interval invariants. This function still
/// performs a sanity check on all keys to avoid silly mistakes. It is, however,
/// considerably faster than ['from_pairs'](from_pairs)
pub fn from_ascending_pairs(xs: Pairs<ByteArray, value>) -> Dict<key, value> {
  let Void = check_ascending_list(xs)
  Dict { inner: xs }
}

fn check_ascending_list(xs: Pairs<ByteArray, value>) {
  when xs is {
    [] -> Void
    [_] -> Void
    [Pair(x0, _), Pair(x1, _) as e, ..rest] ->
      if builtin.less_than_bytearray(x0, x1) {
        check_ascending_list([e, ..rest])
      } else {
        fail @"keys in associative list aren't in ascending order"
      }
  }
}

/// Like [`from_ascending_pairs`](#from_ascending_pairs) but fails if **any**
/// value doesn't satisfy the predicate.
///
/// ```aiken
/// let pairs = [Pair("a", 100), Pair("b", 200), Pair("c", 300)]
///
/// dict.from_ascending_pairs_with(pairs, fn(x) { x <= 250 }) // fail
/// ```
pub fn from_ascending_pairs_with(
  xs: Pairs<ByteArray, value>,
  predicate: fn(value) -> Bool,
) -> Dict<key, value> {
  let Void = check_ascending_pairs_with(xs, predicate)
  Dict { inner: xs }
}

fn check_ascending_pairs_with(
  xs: Pairs<ByteArray, value>,
  predicate: fn(value) -> Bool,
) {
  when xs is {
    [] -> Void
    [Pair(_, v)] ->
      if predicate(v) {
        Void
      } else {
        fail @"value doesn't satisfy predicate"
      }
    [Pair(x0, v0), Pair(x1, _) as e, ..rest] ->
      if builtin.less_than_bytearray(x0, x1) {
        if predicate(v0) {
          check_ascending_pairs_with([e, ..rest], predicate)
        } else {
          fail @"value doesn't satisfy predicate"
        }
      } else {
        fail @"keys in pairs aren't in ascending order"
      }
  }
}

/// Construct a dictionary from a list of key-value pairs. Note that when a key is present
/// multiple times, the first occurrence prevails.
///
/// ```aiken
/// let pairs = [Pair("a", 100), Pair("c", 300), Pair("b", 200)]
///
/// let result =
///   dict.from_pairs(pairs)
///     |> dict.to_pairs()
///
/// result == [Pair("a", 100), Pair("b", 200), Pair("c", 300)]
/// ```
pub fn from_pairs(self: Pairs<ByteArray, value>) -> Dict<key, value> {
  Dict { inner: do_from_pairs(self) }
}

fn do_from_pairs(xs: Pairs<ByteArray, value>) -> Pairs<ByteArray, value> {
  when xs is {
    [] -> []
    [Pair(k, v), ..rest] ->
      do_insert_with(do_from_pairs(rest), k, v, strategy.keep_right())
  }
}

/// Construct a dictionary from a single key/value pair
pub fn singleton(key k: ByteArray, value v: value) -> Dict<key, value> {
  Dict([Pair(k, v)])
}

// ## Inspecting Forcibly

/// More efficient version of [`contains`](#contains), which fails if the given dict isn't fully contained in the source one.
pub fn expect_contains(
  self: Dict<key, value>,
  subset: Dict<key, value>,
  compare: fn(value, value) -> Ordering,
) -> Void {
  do_expect_contains(self.inner, subset.inner, compare)
}

fn do_expect_contains(
  self: Pairs<ByteArray, value>,
  subset: Pairs<ByteArray, value>,
  compare: fn(value, value) -> Ordering,
) -> Void {
  when subset is {
    [] -> Void
    [head_subset, ..tail_subset] -> {
      let head_superset, tail_superset <- pairs.expect_pop_until_key_and_then(
        self,
        head_subset.1st,
      )
      expect Less != compare(head_superset, head_subset.2nd)
      do_expect_contains(tail_superset, tail_subset, compare)
    }
  }
}

/// More efficient version of [`find`](#find), which fails if the value isn't found in the dict.
pub fn expect_find(self: Dict<key, value>, value v: value) -> ByteArray {
  do_expect_find(self.inner, v)
}

fn do_expect_find(self: Pairs<ByteArray, value>, value v: value) -> ByteArray {
  let head = builtin.head_list(self)
  if v == head.2nd {
    head.1st
  } else {
    do_expect_find(builtin.tail_list(self), v)
  }
}

/// More efficient version of [`get`](#get), which fails if the key isn't found in the dict.
pub fn expect_get(self: Dict<key, value>, key k: ByteArray) -> value {
  do_expect_get(self.inner, k)
}

fn do_expect_get(self: Pairs<ByteArray, value>, key k: ByteArray) -> value {
  let Pair(k2, _) as head = builtin.head_list(self)
  if k == k2 {
    head.2nd
  } else {
    do_expect_get(builtin.tail_list(self), k)
  }
}

/// More efficient version of [`has_key`](#has_key), which fails if the key isn't present in the dict
pub fn expect_has_key(self: Dict<key, value>, key k: ByteArray) -> Void {
  expect do_expect_has_key(self.inner, k)
}

fn do_expect_has_key(self: Pairs<ByteArray, value>, key k: ByteArray) -> Bool {
  builtin.head_list(self).1st == k || do_expect_has_key(
    builtin.tail_list(self),
    k,
  )
}

// ## Inspecting

/// Check whether a dictionary is fully _"contained"_ within another using the comparison function. A dict is _contained_ in another if:
///
/// 1. All its keys also exist in the first dict
/// 2. Each value is at least as large according to the comparison function
///
/// ```aiken
/// let superset = dict.empty
///   |> dict.insert("a", 10)
///   |> dict.insert("b", 42)
///
/// dict.contains(superset, dict.empty, int.compare)
/// dict.contains(superset, dict.from_pairs([Pair("a", 1)]), int.compare)
/// dict.contains(superset, dict.from_pairs([Pair("a", 1), Pair("b", 42)]), int.compare)
/// !dict.contains(superset, dict.from_pairs([Pair("a", 14)]), int.compare)
/// !dict.contains(superset, dict.from_pairs([Pair("a", 1), Pair("c", 1)]), int.compare)
/// ```
pub fn contains(
  self: Dict<key, value>,
  subset: Dict<key, value>,
  compare: fn(value, value) -> Ordering,
) -> Bool {
  do_contains(self.inner, subset.inner, compare)
}

fn do_contains(
  self: Pairs<ByteArray, value>,
  subset: Pairs<ByteArray, value>,
  compare: fn(value, value) -> Ordering,
) -> Bool {
  when subset is {
    [] -> True
    [head_subset, ..tail_subset] -> {
      let head_superset, tail_superset <- pairs.pop_until_key_and_then(
        self,
        head_subset.1st,
      )
      and {
        when head_superset is {
          None -> False
          Some(head_superset) -> Less != compare(head_superset, head_subset.2nd)
        },
        do_contains(tail_superset, tail_subset, compare),
      }
    }
  }
}

/// Finds a value in the dictionary, and returns the first key found to have that value.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert(key: "a", value: 42)
///     |> dict.insert(key: "b", value: 14)
///     |> dict.insert(key: "c", value: 42)
///     |> dict.find(42)
///
/// result == Some("a")
/// ```
pub fn find(self: Dict<key, value>, value v: value) -> Option<ByteArray> {
  do_find(self.inner, v)
}

fn do_find(self: Pairs<ByteArray, value>, value v: value) -> Option<ByteArray> {
  when self is {
    [] -> None
    [head, ..rest] ->
      if v == head.2nd {
        Some(head.1st)
      } else {
        do_find(rest, v)
      }
  }
}

/// Get a value in the dict by its key.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert(key: "a", value: "Aiken")
///     |> dict.get(key: "a")
///
///  result == Some("Aiken")
/// ```
pub fn get(self: Dict<key, value>, key: ByteArray) -> Option<value> {
  do_get(self.inner, key, Some, fn() { None })
}

/// Get a value from the dict by its key, or fallback to a default one.
///
/// ```aiken
/// let kvs =
///   dict.empty
///     |> dict.insert(key: "a", value: 42)
///     |> dict.insert(key: "b", value: 14)
///
/// dict.get_or_else(kvs, "a", fn() { 0 }) == 42
/// dict.get_or_else(kvs, "b", fn() { 0 }) == 14
/// dict.get_or_else(kvs, "c", fn() { 0 }) == 0
/// ```
pub fn get_or_else(
  self: Dict<key, value>,
  key: ByteArray,
  or_else: fn() -> value,
) -> value {
  do_get(self.inner, key, identity, or_else)
}

fn do_get(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
  return: fn(value) -> result,
  or_else: fn() -> result,
) -> result {
  when self is {
    [] -> or_else()
    [Pair(k2, _) as head, ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          return(head.2nd)
        } else {
          or_else()
        }
      } else {
        do_get(rest, k, return, or_else)
      }
  }
}

/// Check if a key exists in the dictionary.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert(key: "a", value: "Aiken")
///     |> dict.has_key("a")
///
/// result == True
/// ```
pub fn has_key(self: Dict<key, value>, key k: ByteArray) -> Bool {
  do_has_key(self.inner, k)
}

fn do_has_key(self: Pairs<ByteArray, value>, key k: ByteArray) -> Bool {
  when self is {
    [] -> False
    [Pair(k2, _), ..rest] ->
      if builtin.less_than_bytearray(k2, k) {
        do_has_key(rest, k)
      } else {
        k == k2
      }
  }
}

/// Efficiently checks whether a dictionary is empty.
/// ```aiken
/// dict.is_empty(dict.empty) == True
/// ```
pub fn is_empty(self: Dict<key, value>) -> Bool {
  self.inner == []
}

/// Extract all the keys present in a given `Dict`.
///
/// ```aiken
/// let result =
///   dict.empty
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

fn do_keys(self: Pairs<ByteArray, value>) -> List<ByteArray> {
  when self is {
    [] -> []
    [Pair(k, _), ..rest] -> [k, ..do_keys(rest)]
  }
}

/// Return the number of key-value pairs in the dictionary.
///
/// ```aiken
/// let result =
///   dict.empty
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

fn do_size(self: Pairs<key, value>) -> Int {
  when self is {
    [] -> 0
    [_, ..rest] -> 1 + do_size(rest)
  }
}

/// Extract all the values present in a given `Dict`.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert("a", 14)
///     |> dict.insert("b", 42)
///     |> dict.insert("c", 1337)
///     |> dict.values()
///
/// result == [14, 42, 1337]
/// ```
pub fn values(self: Dict<key, value>) -> List<value> {
  do_values(self.inner)
}

fn do_values(self: Pairs<key, value>) -> List<value> {
  when self is {
    [] -> []
    [Pair(_, v), ..rest] -> [v, ..do_values(rest)]
  }
}

// ## Modifying

/// Remove a key-value pair from the dictionary. If the key is not found, no changes are made.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.delete(key: "a")
///     |> dict.to_pairs()
///
/// result == [Pair("b", 200)]
/// ```
pub fn delete(self: Dict<key, value>, key: ByteArray) -> Dict<key, value> {
  Dict { inner: do_delete(self.inner, key) }
}

fn do_delete(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
) -> Pairs<ByteArray, value> {
  when self is {
    [] -> []
    [Pair(k2, _) as head, ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          rest
        } else {
          self
        }
      } else {
        [head, ..do_delete(rest, k)]
      }
  }
}

/// Like [`union_with`](#union_with) but allows specifying the behavior to adopt when a key is present
/// only in the right dictionary. The first value received corresponds to the value in the right
/// dictionary. When passing `None`, the value is removed and not present in the union.
///
/// ```aiken
/// let left_dict = dict.from_pairs([Pair("a", 100), Pair("b", 200)])
/// let right_dict = dict.from_pairs([Pair("a", 150), Pair("c", 300)])
///
/// let result =
///   dict.difference_with(
///     left_dict,
///     right_dict,
///     fn(_k, _v_left, _v_right, _keep, discard) { discard() },
///     fn(_k, v_right, keep, _discard) { keep(v_right) },
///   )
///     |> dict.to_pairs()
///
/// result == [Pair("b", 200)]
/// ```
pub fn difference_with(
  left: Dict<key, value>,
  right: Dict<key, value>,
  with_both: UnionStrategy<ByteArray, value>,
  with_right: InsertStrategy<ByteArray, value>,
) -> Dict<key, value> {
  Dict {
    inner: do_difference_with(left.inner, right.inner, with_both, with_right),
  }
}

fn do_difference_with(
  left: Pairs<ByteArray, value>,
  right: Pairs<ByteArray, value>,
  with_both: UnionStrategy<ByteArray, value>,
  with_right: InsertStrategy<ByteArray, value>,
) -> Pairs<ByteArray, value> {
  when left is {
    [] -> do_difference_only_right(right, with_right)
    [Pair(k, v), ..rest_left] ->
      when right is {
        [] -> left
        [Pair(k2, v2), ..rest_right] ->
          if builtin.less_than_equals_bytearray(k, k2) {
            if k == k2 {
              with_both(
                k,
                v,
                v2,
                fn(combined) {
                  [
                    Pair(k, combined),
                    ..do_difference_with(
                      rest_left,
                      rest_right,
                      with_both,
                      with_right,
                    )
                  ]
                },
                fn() {
                  do_difference_with(
                    rest_left,
                    rest_right,
                    with_both,
                    with_right,
                  )
                },
              )
            } else {
              [
                Pair(k, v),
                ..do_difference_with(rest_left, right, with_both, with_right)
              ]
            }
          } else {
            with_right(
              k2,
              v2,
              fn(combined) {
                [
                  Pair(k2, combined),
                  ..do_difference_with(left, rest_right, with_both, with_right)
                ]
              },
              fn() {
                do_difference_with(left, rest_right, with_both, with_right)
              },
            )
          }
      }
  }
}

fn do_difference_only_right(
  self: Pairs<ByteArray, value>,
  with_right: InsertStrategy<ByteArray, value>,
) {
  when self is {
    [] -> []
    [Pair(k2, v2), ..rest] -> {
      let t = do_difference_only_right(rest, with_right)
      with_right(
        k2,
        v2,
        fn(combined) { [Pair(k2, combined), ..t] },
        fn() { [Pair(k2, v2), ..t] },
      )
    }
  }
}

/// Keep only the key-value pairs that pass the given predicate.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.insert(key: "c", value: 300)
///     |> dict.filter(fn(k, _v) { k != "a" })
///     |> dict.to_pairs()
///
/// result == [Pair("b", 200), Pair("c", 300)]
/// ```
pub fn filter(
  self: Dict<key, value>,
  with: fn(ByteArray, value) -> Bool,
) -> Dict<key, value> {
  Dict { inner: do_filter(self.inner, with) }
}

fn do_filter(
  self: Pairs<ByteArray, value>,
  with: fn(ByteArray, value) -> Bool,
) -> Pairs<ByteArray, value> {
  when self is {
    [] -> []
    [Pair(k, v) as head, ..rest] ->
      if with(k, v) {
        [head, ..do_filter(rest, with)]
      } else {
        do_filter(rest, with)
      }
  }
}

/// Insert a value in the dictionary at a given key. If the key already exists,
/// its value is **overridden**. If you need ways to combine keys together, use
/// [`insert_with`](#insert_with).
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert(key: "a", value: 1)
///     |> dict.insert(key: "b", value: 2)
///     |> dict.insert(key: "a", value: 3)
///     |> dict.to_pairs()
///
/// result == [Pair("a", 3), Pair("b", 2)]
/// ```
pub fn insert(
  self: Dict<key, value>,
  key k: ByteArray,
  value v: value,
) -> Dict<key, value> {
  Dict { inner: do_insert(self.inner, k, v) }
}

fn do_insert(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
  value v: value,
) -> Pairs<ByteArray, value> {
  when self is {
    [] -> [Pair(k, v)]
    [Pair(k2, _) as head, ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          [Pair(k, v), ..rest]
        } else {
          [Pair(k, v), ..self]
        }
      } else {
        [head, ..do_insert(rest, k, v)]
      }
  }
}

/// Insert a value in the dictionary at a given key. When the key already exists, the provided
/// merge function is called. The value existing in the dictionary is passed as the second argument
/// to the merge function, and the new value is passed as the third argument.
///
/// ```aiken
/// use aiken/collection/dict/strategy
///
/// let result =
///   dict.empty
///     |> dict.insert_with(key: "a", value: 1, with: strategy.sum())
///     |> dict.insert_with(key: "b", value: 2, with: strategy.sum())
///     |> dict.insert_with(key: "a", value: 3, with: strategy.sum())
///     |> dict.to_pairs()
///
/// result == [Pair("a", 4), Pair("b", 2)]
/// ```
pub fn insert_with(
  self: Dict<key, value>,
  key k: ByteArray,
  value v: value,
  with: UnionStrategy<ByteArray, value>,
) -> Dict<key, value> {
  Dict { inner: do_insert_with(self.inner, k, v, with) }
}

/// Apply a function to all key-value pairs in a Dict.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert("a", 100)
///     |> dict.insert("b", 200)
///     |> dict.insert("c", 300)
///     |> dict.map(fn(_k, v) { v * 2 })
///     |> dict.to_pairs()
///
///  result == [Pair("a", 200), Pair("b", 400), Pair("c", 600)]
/// ```
pub fn map(self: Dict<key, a>, with: fn(ByteArray, a) -> b) -> Dict<key, b> {
  Dict { inner: do_map(self.inner, with) }
}

fn do_map(
  self: Pairs<ByteArray, a>,
  with: fn(ByteArray, a) -> b,
) -> Pairs<ByteArray, b> {
  when self is {
    [] -> []
    [Pair(k, v), ..rest] -> [Pair(k, with(k, v)), ..do_map(rest, with)]
  }
}

/// Remove a key-value pair from the dictionary and return its value. If the key is not found, no changes are made.
///
/// ```aiken
/// let (value, _) =
///   dict.empty
///     |> dict.insert(key: "a", value: 100)
///     |> dict.insert(key: "b", value: 200)
///     |> dict.pop(key: "a")
///
/// value == 100
/// ```
pub fn pop(
  self: Dict<key, value>,
  key: ByteArray,
) -> (Option<value>, Dict<key, value>) {
  do_pop(self.inner, key, fn(value, inner) { (value, Dict { inner }) })
}

fn do_pop(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
  return: fn(Option<value>, Pairs<ByteArray, value>) -> result,
) -> result {
  when self is {
    [] -> return(None, [])
    [Pair(k2, _) as head, ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          return(Some(head.2nd), rest)
        } else {
          return(None, self)
        }
      } else {
        do_pop(rest, k, fn(value, inner) { return(value, [head, ..inner]) })
      }
  }
}

// ## Modifying Forcibly

/// More efficient version of [`delete`](#delete), which fails if the key isn't present in the dict.
pub fn expect_delete(self: Dict<key, value>, key: ByteArray) -> Dict<key, value> {
  Dict { inner: do_expect_delete(self.inner, key) }
}

fn do_expect_delete(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
) -> Pairs<ByteArray, value> {
  let Pair(k2, _) as head = builtin.head_list(self)
  if k == k2 {
    builtin.tail_list(self)
  } else {
    [head, ..do_expect_delete(builtin.tail_list(self), k)]
  }
}

/// More efficient version of [`pop`](#pop), which fails if the key isn't present in the dict.
pub fn expect_pop(
  self: Dict<key, value>,
  key k: ByteArray,
) -> (value, Dict<key, value>) {
  let value, inner <- do_expect_pop(self.inner, k)
  (value, Dict { inner })
}

fn do_expect_pop(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
  return: fn(value, Pairs<ByteArray, value>) -> result,
) -> result {
  let Pair(k2, _) as head = builtin.head_list(self)
  if k == k2 {
    return(head.2nd, builtin.tail_list(self))
  } else {
    let value, tail <- do_expect_pop(builtin.tail_list(self), k)
    return(value, [head, ..tail])
  }
}

/// Drop the first key/value out of a dictionnary, and fails if the dictionnary
/// is empty.
///
/// ```aiken
/// dict.expect_tail(dict.empty) → 💥
/// dict.expect_tail(dict.singleton("a", 1)) == dict.empty
/// dict.expect_tail(dict.from_pairs([Pair("a", 1), Pair("b", 2)])) == dict.singleton("b", 2)
/// ```
pub fn expect_tail(self: Dict<key, value>) -> Dict<key, value> {
  self.inner |> builtin.tail_list |> Dict
}

// ## Combining

/// Combine two dictionaries. If the same key exist in both the left and
/// right dictionary, values from the left are preferred (i.e. left-biaised).
///
/// ```aiken
/// let left_dict = dict.from_pairs([Pair("a", 100), Pair("b", 200)])
/// let right_dict = dict.from_pairs([Pair("a", 150), Pair("c", 300)])
///
/// let result =
///   dict.union(left_dict, right_dict) |> dict.to_pairs()
///
/// result == [Pair("a", 100), Pair("b", 200), Pair("c", 300)]
/// ```
pub fn union(
  left: Dict<key, value>,
  right: Dict<key, value>,
) -> Dict<key, value> {
  Dict { inner: do_union(left.inner, right.inner) }
}

fn do_union(
  left: Pairs<ByteArray, value>,
  right: Pairs<ByteArray, value>,
) -> Pairs<ByteArray, value> {
  when left is {
    [] -> right
    [Pair(k, v), ..rest] -> do_union(rest, do_insert(right, k, v))
  }
}

/// Like [`union`](#union) but allows specifying the behavior to adopt when a key is present
/// in both dictionaries. The first value received corresponds to the value in the left
/// dictionary, whereas the second argument corresponds to the value in the right dictionary.
///
/// When passing `None`, the value is removed and not present in the union.
///
/// ```aiken
/// let left_dict = dict.from_pairs([Pair("a", 100), Pair("b", 200)])
/// let right_dict = dict.from_pairs([Pair("a", 150), Pair("c", 300)])
///
/// let result =
///   dict.union_with(
///     left_dict,
///     right_dict,
///     fn(_k, v1, v2) { Some(v1 + v2) },
///   )
///     |> dict.to_pairs()
///
/// result == [Pair("a", 250), Pair("b", 200), Pair("c", 300)]
/// ```
pub fn union_with(
  left: Dict<key, value>,
  right: Dict<key, value>,
  with: UnionStrategy<ByteArray, value>,
) -> Dict<key, value> {
  Dict { inner: do_union_with(left.inner, right.inner, with) }
}

fn do_union_with(
  left: Pairs<ByteArray, value>,
  right: Pairs<ByteArray, value>,
  with: UnionStrategy<ByteArray, value>,
) -> Pairs<ByteArray, value> {
  when left is {
    [] -> right
    [Pair(k, v), ..rest] ->
      do_union_with(rest, do_insert_with(right, k, v, with), with)
  }
}

fn do_insert_with(
  self: Pairs<ByteArray, value>,
  key k: ByteArray,
  value v: value,
  with: UnionStrategy<ByteArray, value>,
) -> Pairs<ByteArray, value> {
  when self is {
    [] -> [Pair(k, v)]
    [Pair(k2, _) as head, ..rest] ->
      if builtin.less_than_equals_bytearray(k, k2) {
        if k == k2 {
          with(
            k,
            head.2nd,
            v,
            fn(combined) { [Pair(k, combined), ..rest] },
            fn() { rest },
          )
        } else {
          [Pair(k, v), ..self]
        }
      } else {
        [head, ..do_insert_with(rest, k, v, with)]
      }
  }
}

// ## Transforming

/// Fold over the key-value pairs in a dictionary. The fold direction follows keys
/// in ascending order and is done from left-to-right.
///
/// ```aiken
/// let result =
///   dict.empty
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
  self: Pairs<ByteArray, value>,
  zero: result,
  with: fn(ByteArray, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [Pair(k, v), ..rest] -> do_foldl(rest, with(k, v, zero), with)
  }
}

/// A function callback to accumulate two returned values at once. See also [`foldl2`](#foldl2) and [`foldr2`](#foldr2) about usage.
pub type Fold2<a, b, result> =
  fn(a, b) -> result

pub fn foldl2(
  self: Dict<key, value>,
  zero_a: a,
  zero_b: b,
  with: fn(ByteArray, value, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> result {
  do_foldl2(self.inner, zero_a, zero_b, with, return)
}

fn do_foldl2(
  self: Pairs<ByteArray, value>,
  zero_a: a,
  zero_b: b,
  with: fn(ByteArray, value, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> result {
  when self is {
    [] -> return(zero_a, zero_b)
    [Pair(k, v), ..tail] -> {
      let a, b <- with(k, v, zero_a, zero_b)
      do_foldl2(tail, a, b, with, return)
    }
  }
}

/// Fold over the key-value pairs in a dictionary. The fold direction follows keys
/// in ascending order and is done from right-to-left.
///
/// ```aiken
/// let result =
///   dict.empty
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
  self: Pairs<ByteArray, value>,
  zero: result,
  with: fn(ByteArray, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [Pair(k, v), ..rest] -> with(k, v, do_foldr(rest, zero, with))
  }
}

pub fn foldr2(
  self: Dict<key, value>,
  zero_a: a,
  zero_b: b,
  with: fn(ByteArray, value, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> result {
  do_foldr2(self.inner, with, return)(zero_a, zero_b)
}

fn do_foldr2(
  self: Pairs<key, value>,
  with: fn(key, value, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> Fold2<a, b, result> {
  when self is {
    [] -> return
    [Pair(k, v), ..tail] ->
      do_foldr2(tail, with, fn(a, b) { with(k, v, a, b, return) })
  }
}

/// Get the inner list holding the dictionary data.
///
/// ```aiken
/// let result =
///   dict.empty
///     |> dict.insert("a", 100)
///     |> dict.insert("b", 200)
///     |> dict.insert("c", 300)
///     |> dict.to_pairs()
///
/// result == [Pair("a", 100), Pair("b", 200), Pair("c", 300)]
/// ```
pub fn to_pairs(self: Dict<key, value>) -> Pairs<ByteArray, value> {
  self.inner
}
