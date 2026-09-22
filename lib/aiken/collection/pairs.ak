//// A module for working with associative lists (a.k.a `Pairs`).
////
//// While any function that works on `List` also works on `Pairs`, this module provides some extra helpers
//// that are specifically tailored to working with associative lists. Fundamentally, a `Pairs<key, value>` is
//// a type-alias to `List<Pair<key, value>>`.
////
//// > [!CAUTION]
//// >
//// > Unlike dictionaries (a.k.a. [`Dict`](./dict.html#Dict), associative lists make no assumption
//// > about the ordering of elements within the list. As a result, lookup
//// > functions do traverse the entire list when invoked. They are also not _sets_,
//// > and thus allow for duplicate keys. This is reflected in the functions used
//// > to interact with them.

use aiken/builtin

// ## Inspecting

/// Get all values in the alist associated with a given key.
///
/// ```aiken
/// pairs.get_all([], "a") == []
/// pairs.get_all([Pair("a", 1)], "a") == [1]
/// pairs.get_all([Pair("a", 1), Pair("b", 2)], "a") == [1]
/// pairs.get_all([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [1, 3]
/// ```
pub fn get_all(self: Pairs<key, value>, key k: key) -> List<value> {
  when self is {
    [] -> []
    [Pair(k2, _) as head, ..tail] ->
      if k == k2 {
        [head.2nd, ..get_all(tail, k)]
      } else {
        get_all(tail, k)
      }
  }
}

/// Get the value in the alist by its key.
/// If multiple values with the same key exist, only the first one is returned.
///
/// ```aiken
/// pairs.get_first([], "a") == None
/// pairs.get_first([Pair("a", 1)], "a") == Some(1)
/// pairs.get_first([Pair("a", 1), Pair("b", 2)], "a") == Some(1)
/// pairs.get_first([Pair("a", 1), Pair("b", 2)], "c") == None
/// pairs.get_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == Some(1)
/// ```
pub fn get_first(self: Pairs<key, value>, key k: key) -> Option<value> {
  when self is {
    [] -> None
    [Pair(k2, _) as head, ..tail] ->
      if k == k2 {
        Some(head.2nd)
      } else {
        get_first(tail, k)
      }
  }
}

/// Get the value in the alist by its key.
/// If multiple values with the same key exist, only the last one is returned.
///
/// ```aiken
/// pairs.get_last([], "a") == None
/// pairs.get_last([Pair("a", 1)], "a") == Some(1)
/// pairs.get_last([Pair("a", 1), Pair("b", 2)], "a") == Some(1)
/// pairs.get_last([Pair("a", 1), Pair("b", 2)], "c") == None
/// pairs.get_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == Some(3)
/// ```
pub fn get_last(self: Pairs<key, value>, key k: key) -> Option<value> {
  do_get_last(self, k, None)
}

fn do_get_last(
  self: Pairs<key, value>,
  key k: key,
  last: Option<value>,
) -> Option<value> {
  when self is {
    [] -> last
    [Pair(k2, _) as head, ..tail] ->
      do_get_last(
        tail,
        k,
        if k == k2 {
          Some(head.2nd)
        } else {
          last
        },
      )
  }
}

/// Finds all keys in the alist associated with a given value.
///
/// ```aiken
/// pairs.find_all([], 1) == []
/// pairs.find_all([Pair("a", 1)], 1) == ["a"]
/// pairs.find_all([Pair("a", 1), Pair("b", 2)], 1) == ["a"]
/// pairs.find_all([Pair("a", 1), Pair("b", 2)], 3) == []
/// pairs.find_all([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == ["a", "c"]
/// ```
pub fn find_all(self: Pairs<key, value>, value v: value) -> List<key> {
  when self is {
    [] -> []
    [Pair(_, v2) as head, ..tail] ->
      if v == v2 {
        [head.1st, ..find_all(tail, v)]
      } else {
        find_all(tail, v)
      }
  }
}

/// Finds the first key in the alist associated with a given value, if any.
///
/// ```aiken
/// pairs.find_first([], 1) == None
/// pairs.find_first([Pair("a", 1)], 1) == Some("a")
/// pairs.find_first([Pair("a", 1), Pair("b", 2)], 1) == Some("a")
/// pairs.find_first([Pair("a", 1), Pair("b", 2)], 3) == None
/// pairs.find_first([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == Some("a")
/// ```
pub fn find_first(self: Pairs<key, value>, value v: value) -> Option<key> {
  when self is {
    [] -> None
    [Pair(_, v2) as head, ..tail] ->
      if v == v2 {
        Some(head.1st)
      } else {
        find_first(tail, v)
      }
  }
}

/// Finds the last key in the alist associated with a given value, if any.
///
/// ```aiken
/// pairs.find_last([], 1) == None
/// pairs.find_last([Pair("a", 1)], 1) == Some("a")
/// pairs.find_last([Pair("a", 1), Pair("b", 2)], 1) == Some("a")
/// pairs.find_last([Pair("a", 1), Pair("b", 2)], 3) == None
/// pairs.find_last([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == Some("c")
/// ```
pub fn find_last(self: Pairs<key, value>, value v: value) -> Option<key> {
  do_find_last(self, v, None)
}

fn do_find_last(
  self: Pairs<key, value>,
  value v: value,
  last: Option<key>,
) -> Option<key> {
  when self is {
    [] -> last
    [Pair(_, v2) as head, ..tail] ->
      do_find_last(
        tail,
        v,
        if v == v2 {
          Some(head.1st)
        } else {
          last
        },
      )
  }
}

/// Check if a key exists in the pairs.
///
/// ```aiken
/// pairs.has_key([], "a") == False
/// pairs.has_key([Pair("a", 1)], "a") == True
/// pairs.has_key([Pair("a", 1), Pair("b", 2)], "a") == True
/// pairs.has_key([Pair("a", 1), Pair("b", 2)], "c") == False
/// pairs.has_key([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == True
/// ```
pub fn has_key(self: Pairs<key, value>, key k: key) -> Bool {
  when self is {
    [] -> False
    [Pair(k2, _), ..tail] -> k == k2 || has_key(tail, k)
  }
}

/// Extract all the keys present in a given `Pairs`.
///
/// ```aiken
/// pairs.keys([]) == []
/// pairs.keys([Pair("a", 1)]) == ["a"]
/// pairs.keys([Pair("a", 1), Pair("b", 2)]) == ["a", "b"]
/// pairs.keys([Pair("a", 1), Pair("b", 2), Pair("a", 3)]) == ["a", "b", "a"]
/// ```
pub fn keys(self: Pairs<key, value>) -> List<key> {
  when self is {
    [] -> []
    [Pair(k, _), ..tail] -> [k, ..keys(tail)]
  }
}

/// Extract all the values present in a given `Pairs`.
///
/// ```aiken
/// pairs.values([]) == []
/// pairs.values([Pair("a", 1)]) == [1]
/// pairs.values([Pair("a", 1), Pair("b", 2)]) == [1, 2]
/// pairs.values([Pair("a", 1), Pair("b", 2), Pair("a", 3)]) == [1, 2, 3]
/// ```
pub fn values(self: Pairs<key, value>) -> List<value> {
  when self is {
    [] -> []
    [Pair(_, v), ..tail] -> [v, ..values(tail)]
  }
}

// ## Inspecting Forcibly

/// More efficient version of [`get_first`](#get_first) which fails if no key is found.
///
/// ```aiken
/// pairs.expect_get_first([], "a") → 💥
/// pairs.expect_get_first([Pair("a", 1)], "a") == 1
/// pairs.expect_get_first([Pair("a", 1), Pair("b", 2)], "a") == 1
/// pairs.expect_get_first([Pair("a", 1), Pair("b", 2)], "c") == → 💥
/// pairs.expect_get_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == 1
/// ```
pub fn expect_get_first(self: Pairs<key, value>, key k: key) -> value {
  let Pair(k2, _) as head = builtin.head_list(self)
  if k == k2 {
    head.2nd
  } else {
    expect_get_first(builtin.tail_list(self), k)
  }
}

/// More efficient version of [`get_last`](#get_last) which fails if no key is found.
///
/// ```aiken
/// pairs.expect_get_last([], "a") → 💥
/// pairs.expect_get_last([Pair("a", 1)], "a") == 1
/// pairs.expect_get_last([Pair("a", 1), Pair("b", 2)], "a") == 1
/// pairs.expect_get_last([Pair("a", 1), Pair("b", 2)], "c") → 💥
/// pairs.expect_get_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == 3
/// ```
pub fn expect_get_last(self: Pairs<key, value>, key k: key) -> value {
  do_expect_get_last(
    self,
    k,
    fn() {
      fail @"expect_get_last: not found"
    },
  )
}

fn do_expect_get_last(
  self: Pairs<key, value>,
  key k: key,
  yield: fn() -> value,
) -> value {
  when self is {
    [] -> yield()
    [Pair(k2, _) as head, ..tail] ->
      do_expect_get_last(
        tail,
        k,
        if k == k2 {
          fn() { head.2nd }
        } else {
          yield
        },
      )
  }
}

/// More efficient version of [`find_first`](#find_first) which fails if no element is found.
///
/// ```aiken
/// pairs.expect_find_first([], 1) → 💥
/// pairs.expect_find_first([Pair("a", 1)], 1) == "a"
/// pairs.expect_find_first([Pair("a", 1), Pair("b", 2)], 1) == "a"
/// pairs.expect_find_first([Pair("a", 1), Pair("b", 2)], 3) → 💥
/// pairs.expect_find_first([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == "a"
/// ```
pub fn expect_find_first(self: Pairs<key, value>, value v: value) -> key {
  let Pair(_, v2) as head = builtin.head_list(self)
  if v == v2 {
    head.1st
  } else {
    expect_find_first(builtin.tail_list(self), v)
  }
}

/// More efficient version of [`find_last`](#find_last) which fails if no element is found.
///
/// ```aiken
/// pairs.expect_find_last([], 1) → 💥
/// pairs.expect_find_last([Pair("a", 1)], 1) == "a"
/// pairs.expect_find_last([Pair("a", 1), Pair("b", 2)], 1) == "a"
/// pairs.expect_find_last([Pair("a", 1), Pair("b", 2)], 3) → 💥
/// pairs.expect_find_last([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == "c"
/// ```
pub fn expect_find_last(self: Pairs<key, value>, value v: value) -> key {
  do_expect_find_last(
    self,
    v,
    fn() {
      fail @"expect_find_last: not found"
    },
  )
}

fn do_expect_find_last(
  self: Pairs<key, value>,
  value v: value,
  yield: fn() -> key,
) -> key {
  when self is {
    [] -> yield()
    [Pair(_, v2) as head, ..tail] ->
      do_expect_find_last(
        tail,
        v,
        if v == v2 {
          fn() { head.1st }
        } else {
          yield
        },
      )
  }
}

/// More efficient version of [`has_key`](#has_key), which fails if the key isn't present in the associative list.
///
/// ```aiken
/// pairs.expect_has_key([], "a") → 💥
/// pairs.expect_has_key([Pair("a", 1)], "a") → ✅
/// pairs.expect_has_key([Pair("a", 1), Pair("b", 2)], "a") → ✅
/// pairs.expect_has_key([Pair("a", 1), Pair("b", 2)], "c") → 💥
/// pairs.expect_has_key([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") → ✅
/// ```
pub fn expect_has_key(self: Pairs<key, value>, key k: key) -> Void {
  let Pair(k2, _) = builtin.head_list(self)
  if k2 == k {
    Void
  } else {
    expect_has_key(builtin.tail_list(self), k)
  }
}

// ## Modifying

/// Remove all key-value pairs matching the key from the Pairs. If the key is not found, no changes are made.
///
/// ```aiken
/// pairs.delete_all([], "a") == []
/// pairs.delete_all([Pair("a", 1)], "a") == []
/// pairs.delete_all([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// pairs.delete_all([Pair("a", 1), Pair("b", 2)], "c") == [Pair("a", 1), Pair("b", 2)]
/// pairs.delete_all([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("b", 2)]
/// ```
pub fn delete_all(self: Pairs<key, value>, key k: key) -> Pairs<key, value> {
  when self is {
    [] -> []
    [Pair(k2, v2), ..tail] ->
      if k == k2 {
        delete_all(tail, k)
      } else {
        [Pair(k2, v2), ..delete_all(tail, k)]
      }
  }
}

/// Remove a single key-value pair from the `Pairs`. If the key is not found, no changes are made.
/// Duplicate keys are not deleted. Only the **first** key found is deleted.
///
/// ```aiken
/// pairs.delete_first([], "a") == []
/// pairs.delete_first([Pair("a", 1)], "a") == []
/// pairs.delete_first([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// pairs.delete_first([Pair("a", 1), Pair("b", 2)], "c") == [Pair("a", 1), Pair("b", 2)]
/// pairs.delete_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("b", 2), Pair("a", 3)]
/// ```
pub fn delete_first(self: Pairs<key, value>, key k: key) -> Pairs<key, value> {
  when self is {
    [] -> []
    [Pair(k2, _) as head, ..tail] ->
      if k == k2 {
        tail
      } else {
        [head, ..delete_first(tail, k)]
      }
  }
}

/// Remove a single key-value pair from the Pairs. If the key is not found, no changes are made.
/// Duplicate keys are not deleted. Only the **last** key found is deleted.
///
/// ```aiken
/// pairs.delete_last([], "a") == []
/// pairs.delete_last([Pair("a", 1)], "a") == []
/// pairs.delete_last([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// pairs.delete_last([Pair("a", 1), Pair("b", 2)], "c") == [Pair("a", 1), Pair("b", 2)]
/// pairs.delete_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("a", 1), Pair("b", 2)]
/// ```
pub fn delete_last(self: Pairs<key, value>, key k: key) -> Pairs<key, value> {
  when self is {
    [] -> []
    [Pair(k2, _) as head, ..tail] ->
      if k == k2 {
        let new_tail = delete_last(tail, k)
        if tail == new_tail {
          tail
        } else {
          [head, ..new_tail]
        }
      } else {
        [head, ..delete_last(tail, k)]
      }
  }
}

/// Insert a value in the `Pairs` at a given key. If the key already exists,
/// the value is added in front.
///
/// > [!CAUTION]
/// > The list is only traversed up to the given key and the traversal
/// > stops as soon as a higher key is encountered. Said differently, the list
/// > is assumed to **be ordered by ascending keys**! If it is not, expect the
/// > unexpected.
///
/// ```aiken
/// use aiken/primitive/bytearray
///
/// [Pair("bar", 2), Pair("foo", 3), Pair("foo", 1)] == ([]
///   |> pairs.insert_by_ascending_key(key: "foo", value: 1, compare: bytearray.compare)
///   |> pairs.insert_by_ascending_key(key: "bar", value: 2, compare: bytearray.compare)
///   |> pairs.insert_by_ascending_key(key: "foo", value: 3, compare: bytearray.compare)
/// )
/// ```
pub fn insert_by_ascending_key(
  self: Pairs<key, value>,
  key k: key,
  value v: value,
  compare: fn(key, key) -> Ordering,
) -> Pairs<key, value> {
  when self is {
    [] -> [Pair(k, v)]
    [Pair(k2, _) as head, ..tail] ->
      if Less == compare(k, k2) {
        [Pair(k, v), ..self]
      } else {
        if k == k2 {
          [Pair(k, v), ..self]
        } else {
          [head, ..insert_by_ascending_key(tail, k, v, compare)]
        }
      }
  }
}

/// Like [`insert_by_ascending_key`](#insert_by_ascending_key) but specifies
/// how to combine two values on a key conflict.
///
/// > [!CAUTION]
/// > The list is only traversed up to the given key and the traversal
/// > stops as soon as a higher key is encountered. Said differently, the list
/// > is assumed to **be ordered by ascending keys**! If it is not, expect the
/// > unexpected.
///
/// ```aiken
/// use aiken/primitive/bytearray
///
/// let add_integer = fn(x, y) { x + y }
///
/// [Pair("bar", 2), Pair("foo", 4)] == ([]
///     |> pairs.insert_with_by_ascending_key(key: "foo", value: 1, compare: bytearray.compare, with: add_integer)
///     |> pairs.insert_with_by_ascending_key(key: "bar", value: 2, compare: bytearray.compare, with: add_integer)
///     |> pairs.insert_with_by_ascending_key(key: "foo", value: 3, compare: bytearray.compare, with: add_integer)
/// )
/// ```
pub fn insert_with_by_ascending_key(
  self: Pairs<key, value>,
  key k: key,
  value v: value,
  compare: fn(key, key) -> Ordering,
  with: fn(value, value) -> value,
) -> Pairs<key, value> {
  when self is {
    [] -> [Pair(k, v)]
    [Pair(k2, _) as head, ..tail] ->
      if Less == compare(k, k2) {
        [Pair(k, v), ..self]
      } else {
        if k == k2 {
          [Pair(k, with(v, head.2nd)), ..tail]
        } else {
          [head, ..insert_with_by_ascending_key(tail, k, v, compare, with)]
        }
      }
  }
}

/// Apply a function to all key-value pairs in a alist, replacing the values.
///
/// ```aiken
/// [Pair("a", 200), Pair("b", 400)] == ([Pair("a", 100), Pair("b", 200)]
///   |> pairs.map(, fn(_k, v) { v * 2 })
/// )
/// ```
pub fn map(
  self: Pairs<key, value>,
  with: fn(key, value) -> result,
) -> Pairs<key, result> {
  when self is {
    [] -> []
    [Pair(k, v), ..tail] -> [Pair(k, with(k, v)), ..map(tail, with)]
  }
}

/// Drop elements from an associative list until a predicate is satisfied.
/// Returns the first key/value pair that satisfies the predicate, and the rest
/// of the list after that key/value pair.
///
/// ```aiken
/// let predicate = fn(k, v) { k == "a" && v > 1 }
///
/// expect (None, []) = pairs.pop_until([], predicate)
/// expect (None, []) = pairs.pop_until([Pair("a", 1), Pair("b", 2)], predicate)
/// expect (Some(Pair("a", 3), []) = pairs.pop_until([Pair("a", 1), Pair("b", 2), Pair("a", 3)], predicate)
/// ```
pub fn pop_until(
  self: Pairs<key, value>,
  until: fn(key, value) -> Bool,
) -> (Option<Pair<key, value>>, Pairs<key, value>) {
  pop_until_and_then(self, until, as_tuple)
}

/// Like [`pop_until`](#pop_until) but leverages backpassing.
///
/// ```aiken
/// let predicate = fn(k, v) { k == "a" && v > 1 }
///
/// expect None, [] <- pairs.pop_until_and_then([], predicate)
/// expect None, [] <- pairs.pop_until_and_then([Pair("a", 1), Pair("b", 2)], predicate)
/// expect Some(Pair("a", 3), [] <- pairs.pop_until_and_then([Pair("a", 1), Pair("b", 2), Pair("a", 3)], predicate)
/// ```
pub fn pop_until_and_then(
  self: Pairs<key, value>,
  until: fn(key, value) -> Bool,
  return: fn(Option<Pair<key, value>>, Pairs<key, value>) -> result,
) -> result {
  when self is {
    [] -> return(None, self)
    [Pair(k, v) as head, ..tail] ->
      if until(k, v) {
        return(Some(head), tail)
      } else {
        pop_until_and_then(tail, until, return)
      }
  }
}

/// Drop elements from an associative list until a given key is encountered.
/// Returns the first value at that key (if any), and the rest of the list after
/// that key/value pair.
///
/// ```aiken
/// expect (None, []) = pairs.pop_until_key([], "a")
/// expect (Some(1), [Pair("b", 2)]) = pairs.pop_until_key([Pair("a", 1), Pair("b", 2)], "a")
/// expect (Some(3), []) = pairs.pop_until_key([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "c")
/// expect (None, []) = pairs.pop_until_key([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "")
/// ```
pub fn pop_until_key(
  self: Pairs<key, value>,
  until: key,
) -> (Option<value>, Pairs<key, value>) {
  pop_until_key_and_then(self, until, as_tuple)
}

/// A version of [`pop_until_key`](#pop_until_key) which leverages backpassing.
///
/// ```aiken
/// expect None, [] <- pairs.pop_until_key_and_then([], "a")
/// expect Some(1), [Pair("b", 2)] <- pairs.pop_until_key_and_then([Pair("a", 1), Pair("b", 2)], "a")
/// expect Some(3), [] <- pairs.pop_until_key_and_then([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "c")
/// expect None, [] <- pairs.pop_until_key_and_then([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "")
/// ```
pub fn pop_until_key_and_then(
  self: Pairs<key, value>,
  until: key,
  return: fn(Option<value>, Pairs<key, value>) -> result,
) -> result {
  when self is {
    [] -> return(None, self)
    [Pair(k, _) as head, ..tail] ->
      if until == k {
        return(Some(head.2nd), tail)
      } else {
        pop_until_key_and_then(tail, until, return)
      }
  }
}

/// Insert a value in the `Pairs` at a given key. If the key already exists,
/// its value is replaced.
///
/// > [!CAUTION]
/// > The list is only traversed up to the given key and the traversal
/// > stops as soon as a higher key is encountered. Said differently, the list
/// > is assumed to **be ordered by ascending keys**! If it is not, expect the
/// > unexpected.
///
/// ```aiken
/// use aiken/primitive/bytearray
///
/// [Pair("bar", 2), Pair("foo", 3)] == ([]
///   |> pairs.repsert_by_ascending_key(key: "foo", value: 1, compare: bytearray.compare)
///   |> pairs.repsert_by_ascending_key(key: "bar", value: 2, compare: bytearray.compare)
///   |> pairs.repsert_by_ascending_key(key: "foo", value: 3, compare: bytearray.compare)
/// )
/// ```
pub fn repsert_by_ascending_key(
  self: Pairs<key, value>,
  key k: key,
  value v: value,
  compare: fn(key, key) -> Ordering,
) -> Pairs<key, value> {
  when self is {
    [] -> [Pair(k, v)]
    [Pair(k2, v2), ..tail] ->
      if compare(k, k2) == Less {
        [Pair(k, v), ..self]
      } else {
        if k == k2 {
          [Pair(k, v), ..tail]
        } else {
          [Pair(k2, v2), ..repsert_by_ascending_key(tail, k, v, compare)]
        }
      }
  }
}

// ## Modifying Forcibly

/// More efficient version of [`delete_first`](#delete_first), which fails if
/// there's no matching element to delete.
///
/// ```aiken
/// pairs.expect_delete_first([], "a") → 💥
/// pairs.expect_delete_first([Pair("a", 1)], "a") == []
/// pairs.expect_delete_first([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// pairs.expect_delete_first([Pair("a", 1), Pair("b", 2)], "c") → 💥
/// pairs.expect_delete_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("b", 2), Pair("a", 3)]
/// ```
pub fn expect_delete_first(
  self: Pairs<key, value>,
  key k: key,
) -> Pairs<key, value> {
  expect [Pair(k2, _) as head, ..tail] = self
  if k == k2 {
    tail
  } else {
    [head, ..expect_delete_first(tail, k)]
  }
}

/// More efficient version of [`delete_last`](#delete_last), which fails if
/// there's no matching element to delete.
///
/// ```aiken
/// pairs.expect_delete_last([], "a") → 💥
/// pairs.expect_delete_last([Pair("a", 1)], "a") == []
/// pairs.expect_delete_last([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// pairs.expect_delete_last([Pair("a", 1), Pair("b", 2)], "c") → 💥
/// pairs.expect_delete_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("a", 1), Pair("b", 2)]
/// ```
pub fn expect_delete_last(
  self: Pairs<key, value>,
  key k: key,
) -> Pairs<key, value> {
  expect [Pair(k2, _) as head, ..tail] = self
  if k == k2 {
    tail
  } else {
    [head, ..expect_delete_first(tail, k)]
  }
}

/// More efficient version of [`pop_until`](#pop_until), which fails if there's
/// no element matching the predicate.
///
/// ```aiken
/// let predicate = fn(k, v) { k == "a" && v > 1 }
///
/// 💥 = pairs.expect_pop_until([], predicate)
/// 💥 = pairs.expect_pop_until([Pair("a", 1), Pair("b", 2)], predicate)
/// expect (Pair("a", 3), []) = pairs.expect_pop_until([Pair("a", 1), Pair("b", 2), Pair("a", 3)], predicate)
/// ```
pub fn expect_pop_until(
  self: Pairs<key, value>,
  until: fn(key, value) -> Bool,
) -> (Pair<key, value>, Pairs<key, value>) {
  expect_pop_until_and_then(self, until, as_tuple)
}

/// A version of [`expect_pop_until`](#expect_pop_until) which leverages backpassing.
///
/// ```aiken
/// let predicate = fn(k, v) { k == "a" && v > 1 }
///
/// 💥 <- pairs.expect_pop_until_and_then([], predicate)
/// 💥 <- pairs.expect_pop_until([Pair("a", 1), Pair("b", 2)], predicate)
/// expect Pair("a", 3), [] <- pairs.expect_pop_until_and_then([Pair("a", 1), Pair("b", 2), Pair("a", 3)], predicate)
/// ```
pub fn expect_pop_until_and_then(
  self: Pairs<key, value>,
  until: fn(key, value) -> Bool,
  return: fn(Pair<key, value>, Pairs<key, value>) -> result,
) -> result {
  let Pair(k, v) as head = builtin.head_list(self)
  if until(k, v) {
    return(head, builtin.tail_list(self))
  } else {
    expect_pop_until_and_then(builtin.tail_list(self), until, return)
  }
}

/// More efficient version of [`pop_until_key`](#pop_until_key) which fails if the key isn't found.
///
/// ```aiken
/// 💥 = pairs.expect_pop_until_key([], "a")
/// expect (1, [Pair("b", 2)]) = pairs.expect_pop_until_key([Pair("a", 1), Pair("b", 2)], "a")
/// expect (3, []) = pairs.expect_pop_until_key([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "c")
/// 💥 = pairs.expect_pop_until_key([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "")
/// ```
pub fn expect_pop_until_key(
  self: Pairs<key, value>,
  until: key,
) -> (value, Pairs<key, value>) {
  expect_pop_until_key_and_then(self, until, as_tuple)
}

/// A version of [`expect_pop_until_key`](#expect_pop_until_key) which leverages backpassing.
///
/// ```aiken
/// 💥 <- pairs.expect_pop_until_key_and_then([], "a")
/// expect 1, [Pair("b", 2)] <- pairs.expect_pop_until_key_and_then([Pair("a", 1), Pair("b", 2)], "a")
/// expect 3, [] <- pairs.expect_pop_until_key_and_then([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "c")
/// 💥 <- pairs.expect_pop_until_key_and_then([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "")
/// ```
pub fn expect_pop_until_key_and_then(
  self: Pairs<key, value>,
  until: key,
  return: fn(value, Pairs<key, value>) -> result,
) -> result {
  let head = builtin.head_list(self)
  if until == head.1st {
    return(head.2nd, builtin.tail_list(self))
  } else {
    expect_pop_until_key_and_then(builtin.tail_list(self), until, return)
  }
}

// ## Transforming

/// Fold over the key-value pairs in a pairs. The fold direction follows keys
/// in ascending order and is done from left-to-right.
///
/// ```aiken
/// 1400 == ([Pair(1, 100), Pair(2, 200), Pair(3, 300)]
///   |> pairs.foldl(0, fn(k, v, result) { k * v + result })
/// )
///
/// use aiken/primitive/bytearray.{concat}
///
/// "a1b2c3" == ([Pair("a", "1"), Pair("b", "2"), Pair("c", "3")]
///   |> pairs.foldl("", fn(k, v, str) { concat(str, concat(k, v)) })
/// )
/// ```
pub fn foldl(
  self: Pairs<key, value>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [Pair(k, v), ..tail] -> foldl(tail, with(k, v, zero), with)
  }
}

/// Fold over the key-value pairs in a Pairs. The fold direction follows the
/// order of elements in the Pairs and is done from right-to-left.
///
/// ```aiken
/// 1400 == ([Pair(1, 100), Pair(2, 200), Pair(3, 300)]
///   |> pairs.foldr(0, fn(k, v, result) { k * v + result })
/// )
///
/// use aiken/primitive/bytearray.{concat}
///
/// "c3b2a1" == ([Pair("a", "1"), Pair("b", "2"), Pair("c", "3")]
///   |> pairs.foldr("", fn(k, v, str) { concat(str, concat(k, v)) })
/// )
/// ```
pub fn foldr(
  self: Pairs<key, value>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [Pair(k, v), ..tail] -> with(k, v, foldr(tail, zero, with))
  }
}

/// Upcast a `Data` into a `Pairs<Data, Data>`
pub fn from_data(data: Data) -> Option<Pairs<Data, Data>> {
  if data is Pairs<Data, Data> {
    Some(data)
  } else {
    None
  }
}

/// Like [`from_data`](#from_data) but fails if the given Data is not a CBOR map.
pub fn expect_from_data(data: Data) -> Pairs<Data, Data> {
  expect self: Pairs<Data, Data> = data
  self
}

fn as_tuple(a: a, b: b) -> (a, b) {
  (a, b)
}
