use aiken/builtin
use aiken/option

/// Compare two bytearrays lexicographically.
///
/// ```aiken
/// bytearray.compare(#"00", #"FF") == Less
/// bytearray.compare(#"42", #"42") == Equal
/// bytearray.compare(#"FF", #"00") == Greater
/// ```
pub fn compare(left: ByteArray, right: ByteArray) -> Ordering {
  if builtin.less_than_bytearray(left, right) {
    Less
  } else if builtin.equals_bytearray(left, right) {
    Equal
  } else {
    Greater
  }
}

/// Combine two `ByteArray` together.
///
/// ```aiken
/// bytearray.concat(left: #[1, 2, 3], right: #[4, 5, 6]) == #[1, 2, 3, 4, 5, 6]
/// ```
pub fn concat(left: ByteArray, right: ByteArray) -> ByteArray {
  builtin.append_bytearray(left, right)
}

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

/// Returns the suffix of a `ByteArray` after `n` elements.
///
/// ```aiken
/// bytearray.drop(#[1, 2, 3], n: 2) == #[3]
/// ```
pub fn drop(self: ByteArray, n: Int) -> ByteArray {
  builtin.slice_bytearray(n, builtin.length_of_bytearray(self) - n, self)
}

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

/// Left-fold over bytes of a [`ByteArray`](https://aiken-lang.github.io/prelude/aiken.html#ByteArray). Note that every byte given to the callback function is comprised between 0 and 255.
///
/// ```aiken
/// bytearray.foldl(#"acab", fn(byte, acc) { acc * 256 + byte }, 0) == 44203
/// bytearray.foldl(#[1, 2, 3], flip(bytearray.push), #"") == #[3, 2, 1]
/// ```
pub fn foldl(
  self: ByteArray,
  with: fn(Int, result) -> result,
  zero: result,
) -> result {
  do_foldl(self, with, zero, builtin.length_of_bytearray(self), 0)
}

fn do_foldl(
  self: ByteArray,
  with: fn(Int, result) -> result,
  zero: result,
  len: Int,
  cursor: Int,
) -> result {
  if cursor == len {
    zero
  } else {
    do_foldl(
      self,
      with,
      with(builtin.index_bytearray(self, cursor), zero),
      len,
      cursor + 1,
    )
  }
}

test foldl_1() {
  foldl(#[], fn(byte, acc) { byte + acc }, 42) == 42
}

test foldl_2() {
  foldl(#"acab", fn(byte, acc) { acc * 256 + byte }, 0) == 44203
}

test foldl_3() {
  foldl(
    #"356cf088720a169dae0ce0bb1df8588944389fa43322f0d6ef4ed8c069bfd405",
    fn(byte, acc) { acc * 256 + byte },
    0,
  ) == 24165060555594911913195642527692216679757672038384202527929620681761931383813
}

test foldl_4() {
  foldl(#[1, 2, 3, 4, 5], flip(push), #"") == #[5, 4, 3, 2, 1]
}

/// Right-fold over bytes of a [`ByteArray`](https://aiken-lang.github.io/prelude/aiken.html#ByteArray). Note that every byte given to the callback function is comprised between 0 and 255.
///
/// ```aiken
/// bytearray.foldr(#"acab", fn(byte, acc) { acc * 256 + byte }, 0) == 43948
/// bytearray.foldl(#[1, 2, 3], flip(bytearray.push), #"") == #[1, 2, 3]
/// ```
pub fn foldr(
  self: ByteArray,
  with: fn(Int, result) -> result,
  zero: result,
) -> result {
  do_foldr(self, with, zero, builtin.length_of_bytearray(self) - 1)
}

fn do_foldr(
  self: ByteArray,
  with: fn(Int, result) -> result,
  zero: result,
  cursor: Int,
) -> result {
  if cursor < 0 {
    zero
  } else {
    do_foldr(
      self,
      with,
      with(builtin.index_bytearray(self, cursor), zero),
      cursor - 1,
    )
  }
}

test foldr_1() {
  foldr(#[], fn(byte, acc) { byte + acc }, 42) == 42
}

test foldr_2() {
  foldr(#"acab", fn(byte, acc) { acc * 256 + byte }, 0) == 43948
}

test foldr_3() {
  foldr(#[1, 2, 3, 4, 5], flip(push), #"") == #[1, 2, 3, 4, 5]
}

/// Search the start and end positions of a sub-array in a `ByteArray`.
///
/// ```aiken
/// bytearray.index_of("Hello, World!", "World") == Some((7, 11))
/// bytearray.index_of("Hello, World!", "foo") == None
/// bytearray.index_of("Hello, World!", "!") == Some((12, 12))
/// bytearray.index_of("Hello, World!", "o") == Some((4, 4))
/// bytearray.index_of("Hello, World!", "Hello, World!") == Some((0, 12))
/// ```
pub fn index_of(self: ByteArray, bytes: ByteArray) -> Option<(Int, Int)> {
  let offset = length(bytes)

  do_index_of(self, bytes, 0, offset, length(self))
    |> option.map(fn(ix) { (ix, ix + offset - 1) })
}

fn do_index_of(
  self: ByteArray,
  bytes: ByteArray,
  cursor: Int,
  offset: Int,
  size: Int,
) -> Option<Int> {
  if cursor + offset > size {
    None
  } else {
    if builtin.slice_bytearray(cursor, offset, self) == bytes {
      Some(cursor)
    } else {
      do_index_of(self, bytes, cursor + 1, offset, size)
    }
  }
}

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

/// Returns the number of bytes in a `ByteArray`.
///
/// ```aiken
/// bytearray.length(#[1, 2, 3]) == 3
/// ```
pub fn length(self: ByteArray) -> Int {
  builtin.length_of_bytearray(self)
}

test length_1() {
  length(#"") == 0
}

test length_2() {
  length(#"010203") == 3
}

/// Returns `True` when the given `ByteArray` is empty.
///
/// ```aiken
/// bytearray.is_empty(#"") == True
/// bytearray.is_empty(#"00ff") == False
/// ```
pub fn is_empty(self: ByteArray) -> Bool {
  builtin.length_of_bytearray(self) == 0
}

test is_empty_1() {
  is_empty(#"") == True
}

test is_empty_2() {
  is_empty(#"01") == False
}

/// Convert a `String` into a `ByteArray`.
///
/// ```aiken
/// bytearray.from_string(@"ABC") == #"414243"
/// ```
pub fn from_string(str: String) -> ByteArray {
  builtin.encode_utf8(str)
}

test from_string_1() {
  from_string(@"") == ""
}

test from_string_2() {
  from_string(@"ABC") == #"414243"
}

/// Add a byte element in front of a `ByteArray`. When the given byte is
/// greater than 255, it wraps-around. So 256 is mapped to 0, 257 to 1, and so
/// forth.
///
/// ```aiken
/// bytearray.push(#"", 0) == #"00"
/// bytearray.push(#"0203", 1) == #"010203"
/// bytearray.push(#"0203", 257) == #"010203"
/// ```
pub fn push(self: ByteArray, byte: Int) -> ByteArray {
  builtin.cons_bytearray(byte, self)
}

test push_1() {
  push(#[], 0) == #[0]
}

test push_2() {
  push(#[2, 3], 1) == #[1, 2, 3]
}

test push_3() {
  let x = 257
  push(#[2, 3], x) == #[1, 2, 3]
}

/// Reduce bytes in a ByteArray from left to right using the accumulator as left operand.
/// Said differently, this is [`foldl`](#foldl) with callback arguments swapped.
///
/// ```aiken
/// bytearray.reduce(#[1,2,3], bytearray.push, #[]) == #[3, 2, 1]
/// ```
pub fn reduce(
  self: ByteArray,
  with: fn(result, Int) -> result,
  zero: result,
) -> result {
  foldl(self, flip(with), zero)
}

test reduce_1() {
  reduce(#[], push, #[]) == #[]
}

test reduce_2() {
  reduce(#[1, 2, 3], push, #[]) == #[3, 2, 1]
}

/// Extract a `ByteArray` as a slice of another `ByteArray`.
///
/// Indexes are 0-based and inclusive.
///
/// ```aiken
/// bytearray.slice(#[0, 1, 2, 3, 4, 5, 6], start: 1, end: 3) == #[1, 2, 3]
/// ```
pub fn slice(self: ByteArray, start: Int, end: Int) -> ByteArray {
  builtin.slice_bytearray(start, end - start + 1, self)
}

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

/// Returns the n-length prefix of a `ByteArray`.
///
/// ```aiken
/// bytearray.take(#[1, 2, 3], n: 2) == #[1, 2]
/// ```
pub fn take(self: ByteArray, n: Int) -> ByteArray {
  builtin.slice_bytearray(0, n, self)
}

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

/// Convert a `ByteArray` into a `String`.
///
/// ```aiken
/// bytearray.to_string(#"414243") == "ABC"
/// ```
pub fn to_string(self: ByteArray) -> String {
  builtin.decode_utf8(self)
}

test to_string_1() {
  to_string("") == @""
}

test to_string_2() {
  to_string("ABC") == @"ABC"
}
