use aiken/builtin

/// Adds two ByteArrays together using bitwise operations.
///
/// ```aiken
/// bitwise.add(#"00acab", #"00cafe") == #"0177A9"
/// ``
pub fn add(a: ByteArray, b: ByteArray) -> ByteArray {
  if builtin.count_set_bits(b) == 0 {
    a
  } else {
    let carry: ByteArray =
      builtin.and_bytearray(True, a, b) |> builtin.shift_bytearray(1)
    let sum_without_carry: ByteArray = builtin.xor_bytearray(True, a, b)
    add(sum_without_carry, carry)
  }
}
