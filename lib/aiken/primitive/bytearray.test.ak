use aiken/primitive/bytearray.{
  concat, drop, foldl, foldr, from_int_big_endian, from_int_little_endian,
  from_string, index_of, is_empty, length, push, reduce, replicate, slice,
  starts_with, take, test_bit, to_hex, to_int_big_endian, to_int_little_endian,
  to_string,
}

// --------------------------------------------------------- from_int_big_endian

test from_int_big_endian_1() {
  from_int_big_endian(1_000_000, 3) == #"0f4240"
}

test from_int_big_endian_2() {
  from_int_big_endian(1_000_000, 5) == #"00000f4240"
}

test from_int_big_endian_3() {
  from_int_big_endian(0, 8) == #"0000000000000000"
}

test from_int_big_endian_4() fail {
  from_int_big_endian(1_000_000, 1) == #"40"
}

// ------------------------------------------------------ from_int_little_endian

test from_int_little_endian_1() {
  from_int_little_endian(1_000_000, 3) == #"40420f"
}

test from_int_little_endian_2() {
  from_int_little_endian(1_000_000, 5) == #"40420f0000"
}

test from_int_little_endian_3() {
  from_int_little_endian(0, 8) == #"0000000000000000"
}

test from_int_little_endian_4() fail {
  from_int_little_endian(1_000_000, 1) == #"40"
}

// ----------------------------------------------------------------- from_string

test from_string_1() {
  from_string(@"") == ""
}

test from_string_2() {
  from_string(@"ABC") == #"414243"
}

// ----------------------------------------------------------------- replicate

test replicate_1() {
  and {
    replicate(10, 0) == #"00000000000000000000",
    replicate(1, 255) == #"ff",
    replicate(0, 128) == #"",
  }
}

test replicate_2() fail {
  replicate(8193, 0) |> tautology
}

test replicate_3() fail {
  replicate(2, 256) |> tautology
}

test replicate_4() fail {
  replicate(2, -1) |> tautology
}

// -------------------------------------------------------------------- index_of

test index_of_1() {
  index_of("Hello, World!", "World") == Some((7, 11))
}

test index_of_2() {
  index_of("Hello, World!", "foo") == None
}

test index_of_3() {
  index_of("Hello, World!", "!") == Some((12, 12))
}

test index_of_4() {
  index_of("Hello, World!", "o") == Some((4, 4))
}

test index_of_5() {
  index_of("Hello, World!", "Hello, World!") == Some((0, 12))
}

// -------------------------------------------------------------------- is_empty

test is_empty_1() {
  is_empty(#"") == True
}

test is_empty_2() {
  is_empty(#"01") == False
}

// ---------------------------------------------------------------------- length

test length_1() {
  length(#"") == 0
}

test length_2() {
  length(#"010203") == 3
}

// -------------------------------------------------------------------- test_bit

test test_bit_0() {
  test_bit(#"8b765f", 0)
}

test test_bit_1() {
  !test_bit(#"8b765f", 1)
}

test test_bit_2() {
  !test_bit(#"8b765f", 2)
}

test test_bit_20_21_22_23() {
  and {
    test_bit(#"8b765f", 20),
    test_bit(#"8b765f", 21),
    test_bit(#"8b765f", 22),
    test_bit(#"8b765f", 23),
  }
}

test test_bit_3() {
  !test_bit(#"8b765f", 3)
}

test test_bit_7() {
  test_bit(#"8b765f", 7)
}

test test_bit_8() {
  !test_bit(#"8b765f", 8)
}

// ------------------------------------------------------------------------ drop

test drop_1() {
  let x = #"01020304050607"
  drop(x, 2) == #"0304050607"
}

test drop_2() {
  let x = #"01020304050607"
  drop(x, 0) == x
}

test drop_3() {
  let x = #"01"
  drop(x, 1) == #""
}

test drop_4() {
  let x = #""
  drop(x, 2) == #""
}

// ------------------------------------------------------------------------ push

test push_1() {
  push(#[], 0) == #[0]
}

test push_2() {
  push(#[2, 3], 1) == #[1, 2, 3]
}

test push_3() fail {
  let x = 257
  push(#[2, 3], x) == #[1, 2, 3]
}

// ----------------------------------------------------------------------- slice

test slice_1() {
  slice(#"", 1, 2) == #""
}

test slice_2() {
  slice(#"010203", 1, 2) == #"0203"
}

test slice_3() {
  slice(#"010203", 0, 42) == #"010203"
}

test slice_4() {
  slice(#[0, 1, 2, 3, 4], 0, 3) == #[0, 1, 2, 3]
}

test slice_5() {
  slice(#[0, 1, 2, 3, 4], 1, 2) == #[1, 2]
}

// ------------------------------------------------------------------------ take

test take_1() {
  let x = #"01020304050607"
  take(x, 2) == #"0102"
}

test take_2() {
  let x = #"01020304050607"
  take(x, 0) == #""
}

test take_3() {
  let x = #"01"
  take(x, 1) == x
}

test take_4() {
  let x = #"010203"
  take(x, 0) == #""
}

// ---------------------------------------------------------------------- concat

test concat_1() {
  concat(#"", #"") == #""
}

test concat_2() {
  concat(#"", #"01") == #"01"
}

test concat_3() {
  concat(#"0102", #"") == #"0102"
}

test concat_4() {
  concat(#"0102", #"0304") == #"01020304"
}

// ----------------------------------------------------------------------- foldl

test foldl_1() {
  foldl(#[], 42, fn(byte, acc) { byte + acc }) == 42
}

test foldl_2() {
  foldl(#"acab", 0, fn(byte, acc) { acc * 256 + byte }) == 44203
}

test foldl_3() {
  foldl(
    #"356cf088720a169dae0ce0bb1df8588944389fa43322f0d6ef4ed8c069bfd405",
    0,
    fn(byte, acc) { acc * 256 + byte },
  ) == 24165060555594911913195642527692216679757672038384202527929620681761931383813
}

test foldl_4() {
  foldl(#[1, 2, 3, 4, 5], #"", flip(push)) == #[5, 4, 3, 2, 1]
}

// ----------------------------------------------------------------------- foldr

test foldr_1() {
  foldr(#[], 42, fn(byte, acc) { byte + acc }) == 42
}

test foldr_2() {
  foldr(#"acab", 0, fn(byte, acc) { acc * 256 + byte }) == 43948
}

test foldr_3() {
  foldr(#[1, 2, 3, 4, 5], #"", flip(push)) == #[1, 2, 3, 4, 5]
}

// ---------------------------------------------------------------------- reduce

test reduce_1() {
  reduce(#[], #[], push) == #[]
}

test reduce_2() {
  reduce(#[1, 2, 3], #[], push) == #[3, 2, 1]
}

// ----------------------------------------------------------- to_int_big_endian

test to_int_big_endian_1() {
  to_int_big_endian(#"0f4240") == 1_000_000
}

test to_int_big_endian_2() {
  to_int_big_endian(#"00000f4240") == 1_000_000
}

test to_int_big_endian_3() {
  to_int_big_endian(#"0000000000000000") == 0
}

// -------------------------------------------------------- to_int_little_endian

test to_int_little_endian_1() {
  to_int_little_endian(#"40420f") == 1_000_000
}

test to_int_little_endian_2() {
  to_int_little_endian(#"40420f0000") == 1_000_000
}

test to_int_little_endian_3() {
  to_int_little_endian(#"0000000000000000") == 0
}

// ------------------------------------------------------------------- to_string

test to_string_1() {
  to_string("") == @""
}

test to_string_2() {
  to_string("ABC") == @"ABC"
}

// ---------------------------------------------------------------------- to_hex

test to_hex_1() {
  to_hex("Hello world!") == @"48656C6C6F20776F726C6421"
}

test to_hex_2() {
  to_hex("The quick brown fox jumps over the lazy dog") == @"54686520717569636B2062726F776E20666F78206A756D7073206F76657220746865206C617A7920646F67"
}

// ----------------------------------------------------------------- starts_with

test starts_with_1() {
  starts_with("", "")
}

test starts_with_2() {
  starts_with("Hello, World!", "Hello, World!")
}

test starts_with_3() {
  !starts_with("Hello, World!", "hello")
}

test starts_with_4() {
  !starts_with("", "World")
}

test starts_with_5() {
  starts_with("Hello, World", "Hello")
}

test starts_with_6() {
  !starts_with("foo", "foo_")
}
