use aiken/builtin

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

test one_plus_one() {
  let one = builtin.integer_to_bytearray(True, 0, 1)
  let two = builtin.integer_to_bytearray(True, 0, 2)
  add(one, one) == two
}

test add_to_zero() {
  // add(#"00", #"acab") == #"acab"
  add(#"acab", #"00") == #"acab"
}

test mix_addition() {
  let a = builtin.integer_to_bytearray(True, 0, 12)
  let b = builtin.integer_to_bytearray(True, 0, 34151)
  add(a, b) == add(b, a)
}

test small_addition() {
  let a = builtin.integer_to_bytearray(True, 0, 31)
  let b = builtin.integer_to_bytearray(True, 0, 51)
  let result = builtin.integer_to_bytearray(True, 0, 82)
  add(a, b) == result
}

test medium_addition() {
  let a = builtin.integer_to_bytearray(True, 0, 1313)
  let b = builtin.integer_to_bytearray(True, 0, 1514)
  let result = builtin.integer_to_bytearray(True, 0, 2827)
  add(a, b) == result
}

test large_addition() {
  let a = builtin.integer_to_bytearray(True, 0, 123456789)
  let b = builtin.integer_to_bytearray(True, 0, 987654321)
  let result = builtin.integer_to_bytearray(True, 0, 1111111110)
  add(a, b) == result
}

test xlarge_addition() {
  let a =
    builtin.integer_to_bytearray(True, 0, 123456789123456789123456789123456789)
  let b =
    builtin.integer_to_bytearray(True, 0, 987654321987654321987654321987654321)
  let result =
    builtin.integer_to_bytearray(True, 0, 1111111111111111111111111111111111110)
  add(a, b) == result
}

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

test one_minus_one() {
  let one = builtin.integer_to_bytearray(True, 0, 1)
  subtract(one, one) == #"00"
}

test small_subtraction1() {
  let a = builtin.integer_to_bytearray(True, 0, 31)
  let b = builtin.integer_to_bytearray(True, 0, 51)
  let result = builtin.integer_to_bytearray(True, 0, 256 - 20)
  subtract(a, b) == result
}

test small_subtraction2() {
  let a = builtin.integer_to_bytearray(True, 0, 31)
  let b = builtin.integer_to_bytearray(True, 0, 51)
  let result = builtin.integer_to_bytearray(True, 0, 20)
  subtract(b, a) == result
}

pub fn multiply(a: ByteArray, b: ByteArray) -> ByteArray {
  do_multiply(a, b, #"00")
}

pub fn do_multiply(a: ByteArray, b: ByteArray, acc: ByteArray) -> ByteArray {
  trace acc
  if builtin.count_set_bits(b) == 0 {
    acc
  } else {
    // Check the least significant bit of b.
    // If it is set, then add the current value of a to the accumulator.
    let bit_set = builtin.and_bytearray(True, b, #"01")
    let new_acc =
      if builtin.count_set_bits(bit_set) > 0 {
        add(a, acc)
      } else {
        acc
      }
    // trace new_acc
    // Shift a left by 1 (multiply a by 2).
    let new_a = builtin.shift_bytearray(a, 1)
    // trace new_a
    // Shift b right by 1 (divide b by 2).
    let new_b = builtin.shift_bytearray(b, -1)

    // trace new_b
    do_multiply(new_a, new_b, new_acc)
  }
}

test small_multiply() {
  let a = builtin.integer_to_bytearray(True, 0, 2)
  let b = builtin.integer_to_bytearray(True, 0, 3)
  let result = builtin.integer_to_bytearray(True, 0, 6)
  multiply(a, b) == result
}

test medium_multiply() {
  let a = builtin.integer_to_bytearray(True, 0, 21)
  let b = builtin.integer_to_bytearray(True, 0, 31)
  let result = builtin.integer_to_bytearray(True, 0, 651)
  multiply(a, b) == result
}
