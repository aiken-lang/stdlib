//// A module for working with Map Data.
////
//// These Maps are non-ordered lists of key-value pairs,
//// which preserve no invariant on the order of the keys or the duplication of keys.

/// Remove a single key-value pair from the Map. If the key is not found, no changes are made.
/// Duplicate keys are not removed. Only the **first** key found is removed.
///
/// ```aiken
/// map.remove_first([], "a") == []
/// map.remove_first([Pair("a", 1)], "a") == []
/// map.remove_first([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// map.remove_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("b", 2), Pair("a", 3)]
/// ```
pub fn remove_first(self: Map<key, value>, key k: key) -> Map<key, value> {
  when self is {
    [] ->
      []
    [Pair(k2, v2), ..rest] ->
      if k == k2 {
        rest
      } else {
        [Pair(k2, v2), ..remove_first(rest, k)]
      }
  }
}

test remove_first_1() {
  remove_first([], "a") == []
}

test remove_first_2() {
  remove_first([Pair("a", 14)], "a") == []
}

test remove_first_3() {
  let fixture =
    [Pair("a", 14)]
  remove_first(fixture, "b") == fixture
}

test remove_first_4() {
  let fixture =
    [Pair("a", 1), Pair("b", 2), Pair("a", 3)]
  remove_first(fixture, "a") == [Pair("b", 2), Pair("a", 3)]
}

/// Remove a single key-value pair from the Map. If the key is not found, no changes are made.
/// Duplicate keys are not removed. Only the **last** key found is removed.
///
/// ```aiken
/// map.remove_last([], "a") == []
/// map.remove_last([Pair("a", 1)], "a") == []
/// map.remove_last([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// map.remove_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("a", 1), Pair("b", 2)]
/// ```
pub fn remove_last(self: Map<key, value>, key k: key) -> Map<key, value> {
  when self is {
    [] ->
      []
    [Pair(k2, v2), ..rest] ->
      if k == k2 {
        let tail = remove_last(rest, k)
        if tail == rest {
          rest
        } else {
          [Pair(k2, v2), ..tail]
        }
      } else {
        [Pair(k2, v2), ..remove_last(rest, k)]
      }
  }
}

test remove_last_1() {
  remove_last([], "a") == []
}

test remove_last_2() {
  remove_last([Pair("a", 14)], "a") == []
}

test remove_last_3() {
  let fixture =
    [Pair("a", 14)]
  remove_last(fixture, "b") == fixture
}

test remove_last_4() {
  let fixture =
    [Pair("a", 1), Pair("b", 2), Pair("a", 3)]
  remove_last(fixture, "a") == [Pair("a", 1), Pair("b", 2)]
}

/// Remove all key-value pairs matching the key from the Map. If the key is not found, no changes are made.
///
/// ```aiken
/// map.remove_all([], "a") == []
/// map.remove_all([Pair("a", 1)], "a") == []
/// map.remove_all([Pair("a", 1), Pair("b", 2)], "a") == [Pair("b", 2)]
/// map.remove_all([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [Pair("b", 2)]
/// ```
pub fn remove_all(self: Map<key, value>, key k: key) -> Map<key, value> {
  when self is {
    [] ->
      []
    [Pair(k2, v2), ..rest] ->
      if k == k2 {
        remove_all(rest, k)
      } else {
        [Pair(k2, v2), ..remove_all(rest, k)]
      }
  }
}

test remove_all_1() {
  remove_all([], "a") == []
}

test remove_all_2() {
  remove_all([Pair("a", 14)], "a") == []
}

test remove_all_3() {
  let fixture =
    [Pair("a", 14)]
  remove_all(fixture, "b") == fixture
}

test remove_all_4() {
  let fixture =
    [Pair("a", 1), Pair("b", 2), Pair("a", 3)]
  remove_all(fixture, "a") == [Pair("b", 2)]
}

/// Finds the first key in the map associated with a given value, if any.
///
/// ```aiken
/// map.find_first([], 1) == None
/// map.find_first([Pair("a", 1)], 1) == Some("a")
/// map.find_first([Pair("a", 1), Pair("b", 2)], 1) == Some("a")
/// map.find_first([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == Some("a")
/// ```
pub fn find_first(self: Map<key, value>, v: value) -> Option<key> {
  when self is {
    [] -> None
    [Pair(k2, v2), ..rest] ->
      if v == v2 {
        Some(k2)
      } else {
        find_first(rest, v)
      }
  }
}

test find_first_1() {
  find_first([], "a") == None
}

test find_first_2() {
  find_first([Pair("a", 14)], 14) == Some("a")
}

test find_first_3() {
  find_first([Pair("a", 14)], 42) == None
}

test find_first_4() {
  find_first([Pair("a", 14), Pair("b", 42), Pair("c", 14)], 14) == Some("a")
}

/// Finds the last key in the map associated with a given value, if any.
///
/// ```aiken
/// map.find_last([], 1) == None
/// map.find_last([Pair("a", 1)], 1) == Some("a")
/// map.find_last([Pair("a", 1), Pair("b", 2)], 1) == Some("a")
/// map.find_last([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == Some("c")
/// ```
pub fn find_last(self: Map<key, value>, v: value) -> Option<key> {
  when self is {
    [] -> None
    [Pair(k2, v2), ..rest] ->
      if v == v2 {
        when find_last(rest, v) is {
          None -> Some(k2)
          some -> some
        }
      } else {
        find_last(rest, v)
      }
  }
}

test find_last_1() {
  find_last([], "a") == None
}

test find_last_2() {
  find_last([Pair("a", 14)], 14) == Some("a")
}

test find_last_3() {
  find_last([Pair("a", 14)], 42) == None
}

test find_last_4() {
  find_last([Pair("a", 14), Pair("b", 42), Pair("c", 14)], 14) == Some("c")
}

/// Finds all keys in the map associated with a given value.
///
/// ```aiken
/// map.find_all([], 1) == []
/// map.find_all([Pair("a", 1)], 1) == ["a"]
/// map.find_all([Pair("a", 1), Pair("b", 2)], 1) == ["a"]
/// map.find_all([Pair("a", 1), Pair("b", 2), Pair("c", 1)], 1) == ["a", "c"]
/// ```
pub fn find_all(self: Map<key, value>, v: value) -> List<key> {
  when self is {
    [] ->
      []
    [Pair(k2, v2), ..rest] ->
      if v == v2 {
        [k2, ..find_all(rest, v)]
      } else {
        find_all(rest, v)
      }
  }
}

test find_all_1() {
  find_all([], "a") == []
}

test find_all_2() {
  find_all([Pair("a", 14)], 14) == ["a"]
}

test find_all_3() {
  find_all([Pair("a", 14)], 42) == []
}

test find_all_4() {
  find_all([Pair("a", 14), Pair("b", 42), Pair("c", 14)], 14) == ["a", "c"]
}

/// Fold over the key-value pairs in a Map. The fold direction follows the
/// order of elements in the Map and is done from right-to-left.
///
/// ```aiken
/// let fixture = [
///   Pair(1, 100),
///   Pair(2, 200),
///   Pair(3, 300),
/// ]
///
/// map.foldr(fixture, 0, fn(k, v, result) { k * v + result }) == 1400
/// ```
pub fn foldr(
  self: Map<key, value>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [Pair(k, v), ..rest] -> with(k, v, foldr(rest, zero, with))
  }
}

test foldr_1() {
  foldr([], 14, fn(_, _, _) { 42 }) == 14
}

test foldr_2() {
  foldr(
    [Pair("a", 42), Pair("b", 14)],
    zero: 0,
    with: fn(_, v, total) { v + total },
  ) == 56
}

test foldr_3() {
  let fixture =
    [Pair(1, 100), Pair(2, 200), Pair(3, 300)]

  foldr(fixture, 0, fn(k, v, result) { k * v + result }) == 1400
}

/// Fold over the key-value pairs in a map. The fold direction follows keys
/// in ascending order and is done from left-to-right.
///
/// ```aiken
/// let fixture = [
///   Pair(1, 100),
///   Pair(2, 200),
///   Pair(3, 300),
/// ]
///
/// map.foldl(fixture, 0, fn(k, v, result) { k * v + result }) == 1400
/// ```
pub fn foldl(
  self: Map<key, value>,
  zero: result,
  with: fn(key, value, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [Pair(k, v), ..rest] -> foldl(rest, with(k, v, zero), with)
  }
}

test foldl_1() {
  foldl([], 14, fn(_, _, _) { 42 }) == 14
}

test foldl_2() {
  foldl(
    [Pair("a", 42), Pair("b", 14)],
    zero: 0,
    with: fn(_, v, total) { v + total },
  ) == 56
}

/// Get the value in the map by its key.
/// If multiple values with the same key exist, only the first one is returned.
///
/// ```aiken
/// map.get_first([], "a") == None
/// map.get_first([Pair("a", 1)], "a") == Some(1)
/// map.get_first([Pair("a", 1), Pair("b", 2)], "a") == Some(1)
/// map.get_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == Some(1)
/// ```
pub fn get_first(self: Map<key, value>, key k: key) -> Option<value> {
  when self is {
    [] -> None
    [Pair(k2, v), ..rest] ->
      if k == k2 {
        Some(v)
      } else {
        get_first(rest, k)
      }
  }
}

test get_first_1() {
  get_first([], "a") == None
}

test get_first_2() {
  get_first([Pair("a", 1)], "a") == Some(1)
}

test get_first_3() {
  get_first([Pair("a", 1), Pair("b", 2)], "a") == Some(1)
}

test get_first_4() {
  get_first([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == Some(1)
}

test get_first_5() {
  get_first([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "d") == None
}

/// Get the value in the map by its key.
/// If multiple values with the same key exist, only the last one is returned.
///
/// ```aiken
/// map.get_last([], "a") == None
/// map.get_last([Pair("a", 1)], "a") == Some(1)
/// map.get_last([Pair("a", 1), Pair("b", 2)], "a") == Some(1)
/// map.get_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == Some(3)
/// ```
pub fn get_last(self: Map<key, value>, key k: key) -> Option<value> {
  when self is {
    [] -> None
    [Pair(k2, v), ..rest] ->
      if k == k2 {
        when get_last(rest, k) is {
          None -> Some(v)
          some -> some
        }
      } else {
        get_last(rest, k)
      }
  }
}

test get_last_1() {
  get_last([], "a") == None
}

test get_last_2() {
  get_last([Pair("a", 1)], "a") == Some(1)
}

test get_last_3() {
  get_last([Pair("a", 1), Pair("b", 2)], "a") == Some(1)
}

test get_last_4() {
  get_last([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == Some(3)
}

test get_last_5() {
  get_last([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "d") == None
}

/// Get all values in the map associated with a given key.
///
/// ```aiken
/// map.get_all([], "a") == []
/// map.get_all([Pair("a", 1)], "a") == [1]
/// map.get_all([Pair("a", 1), Pair("b", 2)], "a") == [1]
/// map.get_all([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [1, 3]
/// ```
pub fn get_all(self: Map<key, value>, key k: key) -> List<value> {
  when self is {
    [] ->
      []
    [Pair(k2, v), ..rest] ->
      if k == k2 {
        [v, ..get_all(rest, k)]
      } else {
        get_all(rest, k)
      }
  }
}

test get_all_1() {
  get_all([], "a") == []
}

test get_all_2() {
  get_all([Pair("a", 1)], "a") == [1]
}

test get_all_3() {
  get_all([Pair("a", 1), Pair("b", 2)], "a") == [1]
}

test get_all_4() {
  get_all([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == [1, 3]
}

test get_all_5() {
  get_all([Pair("a", 1), Pair("b", 2), Pair("c", 3)], "d") == []
}

/// Check if a key exists in the map.
///
/// ```aiken
/// map.has_key([], "a") == False
/// map.has_key([Pair("a", 1)], "a") == True
/// map.has_key([Pair("a", 1), Pair("b", 2)], "a") == True
/// map.has_key([Pair("a", 1), Pair("b", 2), Pair("a", 3)], "a") == True
/// ```
pub fn has_key(self: Map<key, value>, k: key) -> Bool {
  when self is {
    [] -> False
    // || is lazy so this is fine
    [Pair(k2, _), ..rest] -> k == k2 || has_key(rest, k)
  }
}

test has_key_1() {
  !has_key([], "a")
}

test has_key_2() {
  has_key([Pair("a", 14)], "a")
}

test has_key_3() {
  !has_key([Pair("a", 14)], "b")
}

test has_key_4() {
  has_key([Pair("a", 14), Pair("b", 42)], "b")
}

test has_key_5() {
  has_key([Pair("a", 14), Pair("b", 42), Pair("a", 42)], "a")
}

/// Extract all the keys present in a given `Map`.
///
/// ```aiken
/// map.keys([]) == []
/// map.keys([Pair("a", 1)]) == ["a"]
/// map.keys([Pair("a", 1), Pair("b", 2)]) == ["a", "b"]
/// map.keys([Pair("a", 1), Pair("b", 2), Pair("a", 3)]) == ["a", "b", "a"]
/// ```
pub fn keys(self: Map<key, value>) -> List<key> {
  when self is {
    [] ->
      []
    [Pair(k, _), ..rest] ->
      [k, ..keys(rest)]
  }
}

test keys_1() {
  keys([]) == []
}

test keys_2() {
  keys([Pair("a", 0)]) == ["a"]
}

test keys_3() {
  keys([Pair("a", 0), Pair("b", 0)]) == ["a", "b"]
}

/// Apply a function to all key-value pairs in a map, replacing the values.
///
/// ```aiken
/// let fixture = [Pair("a", 100), Pair("b", 200)]
///
/// map.map(fixture, fn(_k, v) { v * 2 }) == [Pair("a", 200), Pair("b", 400)]
/// ```
pub fn map(
  self: Map<key, value>,
  with: fn(key, value) -> result,
) -> Map<key, result> {
  when self is {
    [] ->
      []
    [Pair(k, v), ..rest] ->
      [Pair(k, with(k, v)), ..map(rest, with)]
  }
}

test map_1() {
  let fixture =
    [Pair("a", 1), Pair("b", 2)]

  map(fixture, with: fn(k, _) { k }) == [Pair("a", "a"), Pair("b", "b")]
}

test map_2() {
  let fixture =
    [Pair("a", 1), Pair("b", 2)]

  map(fixture, with: fn(_, v) { v + 1 }) == [Pair("a", 2), Pair("b", 3)]
}

/// Extract all the values present in a given `Map`.
///
/// ```aiken
/// map.values([]) == []
/// map.values([Pair("a", 1)]) == [1]
/// map.values([Pair("a", 1), Pair("b", 2)]) == [1, 2]
/// map.values([Pair("a", 1), Pair("b", 2), Pair("a", 3)]) == [1, 2, 3]
/// ```
pub fn values(self: Map<key, value>) -> List<value> {
  when self is {
    [] ->
      []
    [Pair(_, v), ..rest] ->
      [v, ..values(rest)]
  }
}

test values_1() {
  values([]) == []
}

test values_2() {
  values([Pair("a", 1)]) == [1]
}

test values_3() {
  values([Pair("a", 1), Pair("b", 2)]) == [1, 2]
}

test values_4() {
  values([Pair("a", 1), Pair("b", 2), Pair("a", 3)]) == [1, 2, 3]
}
