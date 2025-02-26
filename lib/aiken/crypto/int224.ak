//// This module implements arithmetic operations in a constrained 224-bit integer field.
//// Operations are performed modulo 2^224, providing a field for cryptographic operations
//// that require 28-byte values.
////
//// The module provides functionality for basic arithmetic operations (addition, subtraction,
//// multiplication) within this constrained field, as well as conversion functions between
//// different representations.

use aiken/builtin
use aiken/crypto/bitwise.{State}

pub type Hash224 =
  ByteArray

/// The prime defining the 224-bit integer field (2^224)
pub const hash224_field =
  builtin.replicate_byte(28, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

pub const field_size = 28

// ## Constructing

/// Constructs a new `Hash224` element from a Big-Endian (most-significant bits first) `ByteArray`.
pub fn from_bytes(bytes: Hash224) -> State<Hash224> {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> bitwise.from_int(hash224_field)
}

/// Constructs a new `Hash224` element from a Little-Endian (least-significant bits first) `ByteArray`.
pub fn from_bytes_little_endian(bytes: ByteArray) -> State<Hash224> {
  bytes
    |> builtin.bytearray_to_integer(False, _)
    |> bitwise.from_int(hash224_field)
}

/// Constructs a new `Hash224` element from an integer, ensuring it's within the valid range of the field.
pub fn from_int(int: Int) -> State<Hash224> {
  bitwise.from_int(int, hash224_field)
}

type Bitwise224Bytes =
  fn(State<Hash224>, ByteArray) -> State<Hash224>

type Bitwise224Int =
  fn(State<Hash224>, Int) -> State<Hash224>

type Bitwise224State =
  fn(State<Hash224>, State<Hash224>) -> State<Hash224>

// ## Modifying

/// Exponentiates a `Hash224` element by a non-negative integer exponent, using repeated squaring.
/// Note that this function returns `zero` for negative exponents.
pub fn scale(self: State<Hash224>, e: Int) -> State<Hash224> {
  bitwise.scale(self, e, mul)
}

/// A faster version of `scale` for the case where the exponent is a power of two.
/// That is, the exponent `e = 2^k` for some non-negative integer `k`.
pub fn scale2(self: State<Hash224>, k: Int) -> State<Hash224> {
  bitwise.scale2(self, k, mul)
}

// ## Combining

const add_s_hash224: Bitwise224State = bitwise.add_state(hash224_field)

/// Adds two `Hash224` elements, ensuring the result stays within the finite field range.
pub fn add(left: State<Hash224>, right: State<Hash224>) -> State<Hash224> {
  add_s_hash224(left, right)
}

const add_bit224: Bitwise224Bytes = bitwise.add_bits(hash224_field, True)

/// Adds a ByteArray to a `Hash224` element, interpreting bytes as a big-endian number.
pub fn add_bytes(
  intermediate: State<Hash224>,
  bytes: ByteArray,
) -> State<Hash224> {
  add_bit224(intermediate, bytes)
}

const add_i224: Bitwise224Int = bitwise.add_int(hash224_field)

/// Adds an integer to a `Hash224` element.
pub fn add_int(intermediate: State<Hash224>, int: Int) -> State<Hash224> {
  add_i224(intermediate, int)
}

const mul_s_hash224: Bitwise224State = bitwise.mul_state(hash224_field)

/// Multiplies two `Hash224` elements, with the result constrained within the finite field.
pub fn mul(left: State<Hash224>, right: State<Hash224>) -> State<Hash224> {
  mul_s_hash224(left, right)
}

const mul_bit224: Bitwise224Bytes = bitwise.mul_bits(hash224_field, True)

/// Multiplies a `Hash224` element by a ByteArray, interpreting bytes as a big-endian number.
pub fn mul_bytes(
  intermediate: State<Hash224>,
  bytes: ByteArray,
) -> State<Hash224> {
  mul_bit224(intermediate, bytes)
}

const mul_i224: Bitwise224Int = bitwise.mul_int(hash224_field)

/// Multiplies a `Hash224` element by an integer.
pub fn mul_int(intermediate: State<Hash224>, int: Int) -> State<Hash224> {
  mul_i224(intermediate, int)
}

const neg224: fn(State<Hash224>) -> State<Hash224> = bitwise.neg(hash224_field)

/// Calculates the additive inverse of a `Hash224` element.
pub fn neg(intermediate: State<Hash224>) -> State<Hash224> {
  neg224(intermediate)
}

const sub_s_hash224: Bitwise224State = bitwise.sub_state(hash224_field)

/// Subtracts one `Hash224` element from another, with the result wrapped within the finite field range.
pub fn sub(left: State<Hash224>, right: State<Hash224>) -> State<Hash224> {
  sub_s_hash224(left, right)
}

const sub_bit224: Bitwise224Bytes = bitwise.sub_bits(hash224_field, True)

/// Subtracts a ByteArray from a `Hash224` element, interpreting bytes as a big-endian number.
pub fn sub_bytes(
  intermediate: State<Hash224>,
  bytes: ByteArray,
) -> State<Hash224> {
  sub_bit224(intermediate, bytes)
}

const sub_i224: Bitwise224Int = bitwise.sub_int(hash224_field)

/// Subtracts an integer from a `Hash224` element.
pub fn sub_int(intermediate: State<Hash224>, int: Int) -> State<Hash224> {
  sub_i224(intermediate, int)
}

// ## Transforming

/// Converts a `Hash224` element back to its integer representation.
pub fn to_int(intermediate: State<Hash224>) -> Int {
  bitwise.to_int(intermediate)
}

/// Converts a `Hash224` element to a Big-Endian (most-significant bits first) `ByteArray`.
pub fn to_bytes(intermediate: State<Hash224>) -> ByteArray {
  bitwise.to_int(intermediate)
    |> builtin.integer_to_bytearray(True, field_size, _)
}

/// Converts a `Hash224` element to a Little-Endian (least-significant bits first) `ByteArray`.
pub fn to_bytes_little_endian(intermediate: State<Hash224>) -> ByteArray {
  bitwise.to_int(intermediate)
    |> builtin.integer_to_bytearray(False, field_size, _)
}
