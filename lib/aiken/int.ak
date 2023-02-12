/// Compare two integers.
///
/// ```aiken
/// compare(14, 42) == Less
/// compare(14, 14) == Equal
/// compare(42, 14) == Greater
/// ```
pub fn compare(left: Int, right: Int) -> Ordering {
  if left < right {
    Less
  } else if left > right {
    Greater
  } else {
    Equal
  }
}
