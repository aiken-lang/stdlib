use aiken/builtin
use aiken/crypto/bitwise.{one, zero}
use aiken/crypto/int256.{
  add, add_bytes, add_int, field, from_bytearray_big_endian,
  from_bytearray_little_endian, from_int, mul, mul_bytes, mul_int, neg, scale,
  scale2, sub, sub_bytes, sub_int, to_bytearray_big_endian,
  to_bytearray_little_endian, to_int,
}

test equal_pad_for_addition() {
  let a: ByteArray = #"acab"
  let b: ByteArray = #"cafe"

  let x =
    a
      |> from_bytearray_big_endian
      |> add_bytes(b)
      |> to_bytearray_big_endian

  x == #"00000000000000000000000000000000000000000000000000000000000177a9"
}

test unequal_pad_for_addition() {
  let a: ByteArray = #"acabbeefface"
  let b: ByteArray = #"cafe"

  let x =
    a
      |> from_bytearray_big_endian
      |> add_bytes(b)
      |> to_bytearray_big_endian

  x == #"0000000000000000000000000000000000000000000000000000acabbef0c5cc"
}

// ## Test for constructing Hash256 elements

test from_int_1() {
  and {
    ( from_int(-1) |> to_int ) == field - 1,
    ( from_int(field) |> to_int ) == 0,
    ( from_int(834884848) |> to_int ) == 834884848,
  }
}

test from_bytes_big_endian_1() {
  ( from_bytearray_big_endian(#"ffff00") |> to_int ) == 16776960
}

test from_bytes_little_endian_1() {
  ( from_bytearray_little_endian(#"ffff00") |> to_int ) == 65535
}

// ## Tests for modifying Hash256 elements

test scale_1() {
  let x = from_int(834884848)

  and {
    ( x |> scale(-1) ) == zero,
    ( x |> scale(0) ) == one,
    ( x |> scale(1) ) == x,
    ( x |> scale(2) |> to_int ) == 697032709419983104,
    ( x |> scale(3) |> to_int ) == 581942047655130761945608192,
    (
      from_int(field - 5)
        |> scale(200)
        |> to_int
    ) != 0,
  }
}

test scale2_1() {
  let a = from_int(2)

  and {
    ( scale2(a, 0) |> to_int ) == 2,
    ( scale2(a, 1) |> to_int ) == 4,
    ( scale2(a, 2) |> to_int ) == 16,
    ( scale2(a, 3) |> to_int ) == 256,
  }
}

// ## Tests for combining Hash256 elements

test add_1() {
  let x = from_int(834884848)
  let y = from_int(field - 1)
  let z = from_int(3)

  and {
    (( add(x, x) |> to_int ) == 1669769696)?,
    (add(y, one) == zero)?,
    (add(z, add(y, one)) == z)?,
  }
}

test add_overflow_1() {
  let a = from_int(field - 1)
  let b = from_int(1)

  ( add(a, b) |> to_int ) == 0
}

test mul_1() {
  let x = from_int(834884848)
  and {
    mul(x, x) == from_int(697032709419983104),
    mul(zero, x) == zero,
    mul(from_int(field - 1), from_int(2)) == from_int(field - 2),
  }
}

test neg_1() {
  and {
    neg(from_int(834884848)) == from_int(field - 834884848),
    neg(zero) == zero,
    neg(one) == from_int(field - 1),
  }
}

test sub_1() {
  let x = from_int(834884848)

  and {
    (sub(x, x) == zero)?,
    (sub(zero, from_int(5)) == from_int(field - 5))?,
  }
}

// ## Tests for transforming Hash256 elements

test to_int_1() {
  to_int(from_int(834884848)) == 834884848
}

test to_bytes_1() {
  (
    to_bytearray_big_endian(from_int(16777215))
      |> builtin.slice_bytearray(29, 32, _)
  ) == #"ffffff"
}

test to_bytes_little_endian_1() {
  let value = 16777215
  let bytes = to_bytearray_little_endian(from_int(value))
  and {
    ( bytes |> builtin.slice_bytearray(0, 3, _) ) == #"ffffff",
    ( bytes |> builtin.bytearray_to_integer(False, _) ) == value,
  }
}

// ## Tests for various operations and edge cases

test add_bytes_1() {
  let x = from_int(100)
  let result = add_bytes(x, #"0a") |> to_int
  result == 110
}

test add_int_1() {
  let x = from_int(100)
  let result = add_int(x, 50) |> to_int
  result == 150
}

test mul_bytes_1() {
  let x = from_int(10)
  let result = mul_bytes(x, #"0a") |> to_int
  result == 100
}

test mul_int_1() {
  let x = from_int(10)
  let result = mul_int(x, 5) |> to_int
  result == 50
}

test sub_bytes_1() {
  let x = from_int(100)

  trace builtin.bytearray_to_integer(True, #"0a")

  let result = sub_bytes(x, #"0a") |> to_int
  result == 90
}

test sub_int_1() {
  let x = from_int(100)
  let result = sub_int(x, 60) |> to_int
  result == 40
}

test sub_underflow_1() {
  let a = from_int(0)
  let b = from_int(1)

  ( sub(a, b) |> to_int ) == field - 1
}

test overflow_handling() {
  let max = from_int(field - 1)
  and {
    (add_int(max, 1) == zero)?,
    (( add_int(max, 2) |> to_int ) == 1)?,
  }
}

test wraparound_behavior() {
  let x = from_int(10)
  let y = from_int(15)
  and {
    ( sub(x, y) |> to_int ) == field - 5,
    (add(sub(x, y), y) == x)?,
  }
}

test from_bytes_tests() {
  let a = #"acabbeefface"
  let b = #"cafe"

  trace from_bytearray_little_endian(a)
  trace 0xfaceefbeabac

  and {
    ( from_bytearray_big_endian(a) |> to_int ) == 0xacabbeefface,
    ( from_bytearray_big_endian(b) |> to_int ) == 0xcafe,
    ( from_bytearray_little_endian(a) |> to_int ) == 0xcefaefbeabac,
    ( from_bytearray_little_endian(b) |> to_int ) == 0xfeca,
  }
}

test add_tests() {
  let a = from_bytearray_big_endian(#"acab")
  let b = from_bytearray_big_endian(#"cafe")

  and {
    (
      add(a, b) |> to_bytearray_big_endian |> builtin.slice_bytearray(29, 32, _)
    ) == #"0177a9",
    add(from_int(0), from_bytearray_big_endian(#"01")) == from_bytearray_big_endian(
      #"01",
    ),
  }
}

test add_communitive() {
  let a = from_bytearray_big_endian(#"acab")
  let b = from_bytearray_big_endian(#"cafe")

  add(a, b) == add(b, a)
}

test add_associativity() {
  let a = from_bytearray_big_endian(#"0101")
  let b = from_bytearray_big_endian(#"0202")
  let c = from_bytearray_big_endian(#"0303")

  add(add(a, b), c) == add(a, add(b, c))
}

test add_identity() {
  let a = from_bytearray_big_endian(#"01")

  add(zero, a) == a
}

test add_bytes_tests() {
  let a = from_int(0)
  let b = from_bytearray_big_endian(#"acab")

  and {
    (
      add_bytes(a, #"cafe")
        |> to_bytearray_big_endian
        |> builtin.slice_bytearray(30, 32, _)
    ) == #"cafe",
    (
      add_bytes(b, #"cafe")
        |> to_bytearray_big_endian
        |> builtin.slice_bytearray(29, 32, _)
    ) == #"0177a9",
  }
}

test sub_tests() {
  let a = from_bytearray_big_endian(#"0177a9")
  let b = from_bytearray_big_endian(#"cafe")

  and {
    (
      sub(a, b) |> to_bytearray_big_endian |> builtin.slice_bytearray(30, 32, _)
    ) == #"acab",
    (
      sub(
        from_bytearray_big_endian(#"77a9"),
        from_bytearray_big_endian(#"cafe"),
      )
        |> to_bytearray_big_endian
        |> builtin.slice_bytearray(30, 32, _)
    ) == #"acab",
  }
}

test sub_identity() {
  let a = from_bytearray_big_endian(#"10")

  sub(a, zero) == a
}

test mul_tests() {
  let a = from_bytearray_big_endian(#"ffff")
  let b = from_bytearray_big_endian(#"ffff")

  ( mul(a, b) |> to_bytearray_big_endian |> builtin.slice_bytearray(28, 32, _) ) == #"fffe0001"
}

test mul_communitive() {
  let a = from_bytearray_big_endian(#"acab")
  let b = from_bytearray_big_endian(#"cafe")

  mul(a, b) == mul(b, a)
}

test mul_associativity() {
  let a = from_bytearray_big_endian(#"33")
  let b = from_bytearray_big_endian(#"44")
  let c = from_bytearray_big_endian(#"55")

  mul(mul(a, b), c) == mul(a, mul(b, c))
}

test mul_identity() {
  let a = from_bytearray_big_endian(#"acab")

  mul(one, a) == a
}

test mul_bytes_tests() {
  let a = from_int(0)
  let b = from_bytearray_big_endian(#"0002")

  and {
    mul_bytes(a, #"cafe") == zero,
    (
      mul_bytes(b, #"0003")
        |> to_bytearray_big_endian
        |> builtin.slice_bytearray(30, 32, _)
    ) == #"0006",
  }
}

test bytes_conversion_roundtrip() {
  let original = #"acabbeefface"

  and {
    (
      to_bytearray_big_endian(from_bytearray_big_endian(original))
        |> builtin.slice_bytearray(
            32 - builtin.length_of_bytearray(original),
            32,
            _,
          )
    ) == original,
    (
      to_bytearray_little_endian(from_bytearray_little_endian(original))
        |> builtin.slice_bytearray(0, builtin.length_of_bytearray(original), _)
    ) == original,
  }
}

test operation_with_zero() {
  and {
    add(zero, zero) == zero,
    mul(zero, from_int(123456)) == zero,
    sub(zero, zero) == zero,
    neg(zero) == zero,
  }
}

test operation_with_large_numbers() {
  let almost_field_size = from_int(field - 1)
  let large_num = from_int(0xffffffffffffffffffffffffffffff)

  and {
    add(almost_field_size, one) == zero,
    mul(large_num, large_num) != zero,
    // Should be non-zero due to modular arithmetic
    neg(almost_field_size) == one,
  }
}
