use aiken/builtin

/// Addition will at most add a single byte to a bytearray. This will prepad the
/// bytearrays to the correct length for addition and it will correct for mismatched
/// lengths.
///
/// ```aiken
/// bitwise.pad_for_addition(#"acab", #"cafe") == (#"00acab", #"00cafe")
/// ```
pub fn pad_for_addition(a: ByteArray, b: ByteArray) -> (ByteArray, ByteArray) {
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

/// Add two ByteArrays, a + b, using bitwise operations. The function 
/// assumes fixed-width (modular) arithmetic. If arbitrary precision is required
/// use `pad_for_addition`.
///
/// -- pad inputs for arbitrary precision
///
/// ```aiken
/// bitwise.add(#"00acab", #"00cafe") == #"0177A9"
/// ```
///
/// -- otherwise
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

/// Subtracts two ByteArrays, a - b, using bitwise operations.
///
/// ```aiken
/// bitwise.subtract(#"77a9", #"cafe") == #"acab"
/// ```
pub fn subtract(a: ByteArray, b: ByteArray) -> ByteArray {
  if builtin.count_set_bits(b) == 0 {
    a
  } else {
    let borrow: ByteArray =
      builtin.and_bytearray(True, builtin.complement_bytearray(a), b)
        |> builtin.shift_bytearray(1)
    let diff_without_borrow: ByteArray = builtin.xor_bytearray(True, a, b)
    subtract(diff_without_borrow, borrow)
  }
}

/// Multiplication will at most add N bytes to a bytearray for a bytearray of size N.
/// This will prepad the bytearrays to the correct length for multiplication and it 
/// will correct for mismatched lengths.
///
/// ```aiken
/// bitwise.pad_for_multiply(#"acab", #"cafe") == (#"0000acab", #"0000cafe")
/// ```
pub fn pad_for_multiply(a: ByteArray, b: ByteArray) -> (ByteArray, ByteArray) {
  let length_a: Int = builtin.length_of_bytearray(a)
  let length_b: Int = builtin.length_of_bytearray(b)
  if length_a >= length_b {
    let diff: Int = length_a - length_b
    (
      builtin.append_bytearray(builtin.replicate_byte(length_a, 0), a),
      builtin.append_bytearray(builtin.replicate_byte(diff + length_a, 0), b),
    )
  } else {
    let diff: Int = length_b - length_a
    (
      builtin.append_bytearray(builtin.replicate_byte(diff + length_b, 0), a),
      builtin.append_bytearray(builtin.replicate_byte(length_b, 0), b),
    )
  }
}
