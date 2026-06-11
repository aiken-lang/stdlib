//// Array helpers built on top of CIP-138 array builtins.
////
//// This module exposes a small safe surface for working with `Array<a>` values.
////
//// ```aiken
//// let xs = array.from_list([11, 22, 33])
//// array.length(xs) == 3
//// array.at(xs, 1) == Some(22)
//// array.at(xs, 99) == None
//// ```

use aiken/builtin

/// Convert a list into an array.
pub fn from_list(self: List<a>) -> Array<a> {
  builtin.list_to_array(self)
}

/// Return the number of elements in an array.
pub fn length(self: Array<a>) -> Int {
  builtin.length_of_array(self)
}

/// Check whether an array is empty.
pub fn is_empty(self: Array<a>) -> Bool {
  length(self) == 0
}

/// Safely index into an array.
///
/// Returns `None` when the index is negative or out of bounds.
pub fn at(self: Array<a>, ix: Int) -> Option<a> {
  if ix < 0 || ix >= length(self) {
    None
  } else {
    Some(builtin.index_array(self, ix))
  }
}

/// Reduce an array from left to right.
pub fn foldl(self: Array<a>, zero: b, with: fn(a, b) -> b) -> b {
  do_foldl(self, 0, length(self), zero, with)
}

fn do_foldl(self: Array<a>, ix: Int, len: Int, acc: b, with: fn(a, b) -> b) -> b {
  if ix >= len {
    acc
  } else {
    do_foldl(self, ix + 1, len, with(builtin.index_array(self, ix), acc), with)
  }
}

/// Reduce an array from right to left.
pub fn foldr(self: Array<a>, zero: b, with: fn(a, b) -> b) -> b {
  do_foldr(self, 0, length(self), zero, with)
}

fn do_foldr(self: Array<a>, ix: Int, len: Int, acc: b, with: fn(a, b) -> b) -> b {
  if ix >= len {
    acc
  } else {
    with(builtin.index_array(self, ix), do_foldr(self, ix + 1, len, acc, with))
  }
}

/// Convert an array back into a list.
pub fn to_list(self: Array<a>) -> List<a> {
  foldr(self, [], fn(item, items) { [item, ..items] })
}

/// Transform every element in an array.
pub fn map(self: Array<a>, with: fn(a) -> result) -> Array<result> {
  self
    |> foldr([], fn(item, items) { [with(item), ..items] })
    |> from_list
}

/// Determine if all elements satisfy the predicate.
///
/// An empty array always satisfies the predicate.
pub fn all(self: Array<a>, predicate: fn(a) -> Bool) -> Bool {
  foldl(self, True, fn(item, ok) { predicate(item) && ok })
}

/// Determine if at least one element satisfies the predicate.
///
/// An empty array never satisfies the predicate.
pub fn any(self: Array<a>, predicate: fn(a) -> Bool) -> Bool {
  foldl(self, False, fn(item, ok) { predicate(item) || ok })
}
