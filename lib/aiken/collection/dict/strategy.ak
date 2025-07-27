//// This module contains strategies used to transform [`Dict`](../dict.html#Dict). You can safely ignore this module if you aren't using [`union_with`](../dict.html#union_with) nor [`insert_with`](../dict.html#insert_with).

/// A strategy for combining two values in a dictionnary that belong to the same key.
pub type UnionStrategy<key, value> =
  fn(key, value, value, KeepValue<key, value>, DiscardValue<key, value>) ->
    Pairs<key, value>

/// A callback to keep a combined value at a given key
pub type KeepValue<key, value> =
  fn(value) -> Pairs<key, value>

/// A callback to discard a value at a given key
pub type DiscardValue<key, value> =
  fn() -> Pairs<key, value>

// ### Union Strategies

/// A strategy which always fail, enforcing the dict contains no duplicate.
///
/// ```aiken
/// fn(_, _, _, _, _) {
///   fail @"unexpected duplicate key found in dict."
/// }
/// ```
pub fn expect_no_duplicate() -> UnionStrategy<key, value> {
  fn(_, _, _, _, _) {
    fail @"unexpected duplicate key found in dict."
  }
}

/// Combine values by keeping the values present in the left-most dict.
///
/// ```aiken
/// fn(_key, left, _right, keep, _discard) { keep(left) }
/// ```
pub fn keep_left() -> UnionStrategy<key, value> {
  fn(_key, left, _right, keep, _discard) { keep(left) }
}

/// Combine values by keeping the values present in the right-most dict.
///
/// ```aiken
/// fn(_key, _left, right, keep, _discard) { keep(right) }
/// ```
pub fn keep_right() -> UnionStrategy<key, value> {
  fn(_key, _left, right, keep, _discard) { keep(right) }
}

/// Combine values by taking their sum.
///
/// ```aiken
/// fn(_key, left, right, keep, _discard) { keep(left + right) }
/// ```
pub fn sum() -> UnionStrategy<key, Int> {
  fn(_key, left, right, keep, _discard) { keep(left + right) }
}

/// Combine values by taking their sum, only if it is non-null. If the
/// resulting sum is 0, discard the key/value entirely.
///
/// ```aiken
/// fn(_key, left, right, keep, discard) {
///   let value = left + right
///   if value == 0 {
///     discard()
///   } else {
///     keep(value)
///   }
/// }
/// ```
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
