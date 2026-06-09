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
