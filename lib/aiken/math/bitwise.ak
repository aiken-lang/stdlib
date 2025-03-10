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

pub fn multiply(a: ByteArray, b: ByteArray) -> ByteArray {
  let length_a: Int = builtin.length_of_bytearray(a)
  let zero: ByteArray = builtin.replicate_byte(length_a, 0)
  let one: ByteArray =
    builtin.append_bytearray(builtin.replicate_byte(length_a, 0), #"01")
  do_multiply(a, b, zero, one)
}

fn do_multiply(
  a: ByteArray,
  b: ByteArray,
  acc: ByteArray,
  one: ByteArray,
) -> ByteArray {
  if builtin.count_set_bits(b) == 0 {
    acc
  } else {
    let bit_set = builtin.and_bytearray(True, b, #"00000001")
    let new_acc =
      if builtin.count_set_bits(bit_set) > 0 {
        add(acc, a)
      } else {
        acc
      }

    let new_a = builtin.shift_bytearray(a, 1)
    // left shift: multiply a by 2
    let new_b = builtin.shift_bytearray(b, -1)
    // right shift: divide b by 2
    do_multiply(new_a, new_b, new_acc, one)
  }
}
