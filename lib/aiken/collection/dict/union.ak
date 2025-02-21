/// A strategy for combining two values in a dictionnary that belong to the same key.
pub type UnionStrategy<key, value> =
  fn(key, value, value, KeepValue<key, value>, DiscardValue<key, value>) ->
    Pairs<key, value>

/// A callback to keep a combined valueat a given key
pub type KeepValue<key, value> =
  fn(value) -> Pairs<key, value>

/// A callback to discard a value at a given key
pub type DiscardValue<key, value> =
  fn() -> Pairs<key, value>

/// A strategy which always fail, enforcing the dict contains no duplicate.
pub fn expect_no_duplicate() -> UnionStrategy<key, value> {
  fn(_, _, _, _, _) {
    fail @"unexpected duplicate key found in dict."
  }
}

/// Combine values by keeping the values present in the left-most dict.
pub fn keep_left() -> UnionStrategy<key, value> {
  fn(_key, left, _right, keep, _discard) { keep(left) }
}

/// Combine values by keeping the values present in the left-most dict.
pub fn keep_right() -> UnionStrategy<key, value> {
  fn(_key, _left, right, keep, _discard) { keep(right) }
}

/// Combine values by taking their sum.
pub fn sum() -> UnionStrategy<key, Int> {
  fn(_key, left, right, keep, _discard) { keep(left + right) }
}

/// Combine values by taking their sum, only if it is non-null. Otherwise,
/// discard the key/value entirely.
pub fn sum_if_non_zero() -> UnionStrategy<key, Int> {
  fn(_key, left, right, keep, discard) {
    let value = left + right
    if value == 0 {
      discard()
    } else {
      keep(value)
    }
  }
}
