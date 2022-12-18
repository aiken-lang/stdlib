use aiken/builtin

/// Convert a `ByteArray` into a `String`
pub fn from_bytearray(bytes: ByteArray) -> String {
  builtin.decode_utf8(bytes)
}

test from_bytearray_1() {
  from_bytearray(#[]) == ""
}

test from_bytearray_2() {
  from_bytearray(#[65, 66, 67]) == "ABC"
}

/// Convert a `String` into a `ByteArray`
pub fn to_bytearray(str: String) -> ByteArray {
  builtin.encode_utf8(str)
}

test to_bytearray_1() {
  to_bytearray("") == #[]
}

test to_bytearray_2() {
  to_bytearray("ABC") == #[65, 66, 67]
}
