use aiken/builtin

/// Addition will at most add a single byte to a bytearray. This will prepad the
/// bytearrays to the correct length for addition and it will correct for mismatched
/// lengths.
///
/// ```aiken
/// bitwise.pad_addition(#"acab", #"cafe") == (#"00acab", #"00cafe")
/// ```
pub fn pad_addition(a: ByteArray, b: ByteArray) -> (ByteArray, ByteArray) {
  let length_a: Int = builtin.length_of_bytearray(a)
  let length_b: Int = builtin.length_of_bytearray(b)
  if length_a >= length_b {
    let diff: Int = length_a - length_b
    (
      builtin.cons_bytearray(0, a),
      builtin.append_bytearray(builtin.replicate_byte(diff + 1, 0), b),
    )
  } else {
    let diff: Int = length_b - length_a
    (
      builtin.append_bytearray(builtin.replicate_byte(diff + 1, 0), a),
      builtin.cons_bytearray(0, b),
    )
  }
}

/// Add two ByteArrays together using bitwise operations. The function assumes
/// fixed-width (modular) arithmetic.
///
/// -- pad inputs for arbitrary precision
///
/// ```aiken
/// bitwise.add(#"00acab", #"00cafe") == #"0177A9"
/// ```
///
/// ```aiken
/// bitwise.add(#"acab", #"cafe") == #"77A9"
/// ```
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
