//// This module implements arithmetic operations in a constrained 224-bit integer field.
//// Operations are performed modulo $2^{224}$, providing a field for cryptographic operations
//// that require 28-byte values.
////
//// The module provides functionality for basic arithmetic operations (addition, subtraction,
//// multiplication) within this constrained field, as well as conversion functions between
//// different representations.

use aiken/builtin
use aiken/crypto/bitwise

pub opaque type Bits224 {
  Bits224
}

pub type State =
  bitwise.State<Bits224>

type Over<a> =
  fn(State, a) -> State

/// The prime defining the 224-bit integer field $2^{224}$
pub const field =
  builtin.replicate_byte(28, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

/// The field size, in **bytes**.
pub const field_size = 28

// ## Constructing

/// Constructs a new `Bits224` element from a Big-Endian (most-significant bits first) `ByteArray`.
pub fn from_bytearray_big_endian(bytes: ByteArray) -> State {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> bitwise.from_int(field)
}

/// Constructs a new `Bits224` element from a Little-Endian (least-significant bits first) `ByteArray`.
pub fn from_bytearray_little_endian(bytes: ByteArray) -> State {
  bytes
    |> builtin.bytearray_to_integer(False, _)
    |> bitwise.from_int(field)
}

/// Constructs a new `Bits224` element from an integer, ensuring it's within the valid range of the field.
pub fn from_int(int: Int) -> State {
  bitwise.from_int(int, field)
}

// ## Modifying

/// Exponentiates a `Bits224` element by a non-negative integer exponent, using repeated squaring.
/// Note that this function returns `zero` for negative exponents.
pub fn scale(self: State, e: Int) -> State {
  bitwise.scale(self, e, mul)
}

/// A faster version of `scale` for the case where the exponent is a power of two.
/// That is, the exponent $e = 2^k$ for some non-negative integer $k$.
pub fn scale2(self: State, k: Int) -> State {
  bitwise.scale2(self, k, mul)
}

// ## Combining

const add_s_bits224: Over<State> = bitwise.add_state(field)

/// Adds two `Bits224` elements, ensuring the result stays within the finite field range.
pub fn add(left: State, right: State) -> State {
  add_s_bits224(left, right)
}

const add_bit224: Over<ByteArray> = bitwise.add_bits(field, True)

/// Adds a ByteArray to a `Bits224` element, interpreting bytes as a big-endian number.
pub fn add_bytes(self: State, bytes: ByteArray) -> State {
  add_bit224(self, bytes)
}

const add_i224: Over<Int> = bitwise.add_int(field)

/// Adds an integer to a `Bits224` element.
pub fn add_int(self: State, int: Int) -> State {
  add_i224(self, int)
}

const mul_s_bits224: Over<State> = bitwise.mul_state(field)

/// Multiplies two `Bits224` elements, with the result constrained within the finite field.
pub fn mul(left: State, right: State) -> State {
  mul_s_bits224(left, right)
}

const mul_bit224: Over<ByteArray> = bitwise.mul_bits(field, True)

/// Multiplies a `Bits224` element by a ByteArray, interpreting bytes as a big-endian number.
pub fn mul_bytes(self: State, bytes: ByteArray) -> State {
  mul_bit224(self, bytes)
}

const mul_i224: Over<Int> = bitwise.mul_int(field)

/// Multiplies a `Bits224` element by an integer.
pub fn mul_int(self: State, int: Int) -> State {
  mul_i224(self, int)
}

const neg224: fn(State) -> State = bitwise.neg(field)

/// Calculates the additive inverse of a `Bits224` element.
pub fn neg(self: State) -> State {
  neg224(self)
}

const sub_s_bits224: Over<State> = bitwise.sub_state(field)

/// Subtracts one `Bits224` element from another, with the result wrapped within the finite field range.
pub fn sub(left: State, right: State) -> State {
  sub_s_bits224(left, right)
}

const sub_bit224: Over<ByteArray> = bitwise.sub_bits(field, True)

/// Subtracts a `ByteArray` from a `Bits224` element, interpreting bytes as a big-endian number.
pub fn sub_bytes(self: State, bytes: ByteArray) -> State {
  sub_bit224(self, bytes)
}

const sub_i224: Over<Int> = bitwise.sub_int(field)

/// Subtracts an integer from a `Bits224` element.
pub fn sub_int(self: State, int: Int) -> State {
  sub_i224(self, int)
}

// ## Transforming

/// Converts a `Bits224` element to a Big-Endian (most-significant bits first) `ByteArray`.
pub fn to_bytearray_big_endian(self: State) -> ByteArray {
  bitwise.to_int(self)
    |> builtin.integer_to_bytearray(True, field_size, _)
}

/// Converts a `Bits224` element to a Little-Endian (least-significant bits first) `ByteArray`.
pub fn to_bytearray_little_endian(self: State) -> ByteArray {
  bitwise.to_int(self)
    |> builtin.integer_to_bytearray(False, field_size, _)
}

/// Converts a `Bits224` element back to its integer representation.
pub fn to_int(self: State) -> Int {
  bitwise.to_int(self)
}
