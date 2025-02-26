//// This module implements arithmetic operations in a constrained 256-bit integer field.
//// Operations are performed modulo 2^256, providing a field for cryptographic operations
//// that require 32-byte values.
////
//// The module provides functionality for basic arithmetic operations (addition, subtraction,
//// multiplication) within this constrained field, as well as conversion functions between
//// different representations.

use aiken/builtin
use aiken/crypto/bitwise.{State}

/// The prime defining the 256-bit integer field (2^256)
pub const hash256_field =
  builtin.replicate_byte(32, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

pub const field_size = 32

pub type Hash256 =
  ByteArray

// ## Constructing

/// Constructs a new `Hash256` element from a Big-Endian (most-significant bits first) `ByteArray`.
pub fn from_bytes(bytes: Hash256) -> State<Hash256> {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> bitwise.from_int(hash256_field)
}

/// Constructs a new `Hash256` element from a Little-Endian (least-significant bits first) `ByteArray`.
pub fn from_bytes_little_endian(bytes: ByteArray) -> State<Hash256> {
  bytes
    |> builtin.bytearray_to_integer(False, _)
    |> bitwise.from_int(hash256_field)
}

/// Constructs a new `Hash256` element from an integer, ensuring it's within the valid range of the field.
pub fn from_int(int: Int) -> State<Hash256> {
  bitwise.from_int(int, hash256_field)
}

type Bitwise256Bytes =
  fn(State<Hash256>, ByteArray) -> State<Hash256>

type Bitwise256Int =
  fn(State<Hash256>, Int) -> State<Hash256>

type Bitwise256State =
  fn(State<Hash256>, State<Hash256>) -> State<Hash256>

// ## Modifying

/// Exponentiates a `Hash256` element by a non-negative integer exponent, using repeated squaring.
/// Note that this function returns `zero` for negative exponents.
pub fn scale(self: State<Hash256>, e: Int) -> State<Hash256> {
  bitwise.scale(self, e, mul)
}

/// A faster version of `scale` for the case where the exponent is a power of two.
/// That is, the exponent `e = 2^k` for some non-negative integer `k`.
pub fn scale2(self: State<Hash256>, k: Int) -> State<Hash256> {
  bitwise.scale2(self, k, mul)
}

// ## Combining

const add_s_hash256: Bitwise256State = bitwise.add_state(hash256_field)

/// Adds two `Hash256` elements, ensuring the result stays within the finite field range.
pub fn add(left: State<Hash256>, right: State<Hash256>) -> State<Hash256> {
  add_s_hash256(left, right)
}

const add_bit256: Bitwise256Bytes = bitwise.add_bits(hash256_field, True)

/// Adds a ByteArray to a `Hash256` element, interpreting bytes as a big-endian number.
pub fn add_bytes(
  intermediate: State<Hash256>,
  bytes: ByteArray,
) -> State<Hash256> {
  add_bit256(intermediate, bytes)
}

const add_i256: Bitwise256Int = bitwise.add_int(hash256_field)

/// Adds an integer to a `Hash256` element.
pub fn add_int(intermediate: State<Hash256>, int: Int) -> State<Hash256> {
  add_i256(intermediate, int)
}

const mul_s_hash256: Bitwise256State = bitwise.mul_state(hash256_field)

/// Multiplies two `Hash256` elements, with the result constrained within the finite field.
pub fn mul(left: State<Hash256>, right: State<Hash256>) -> State<Hash256> {
  mul_s_hash256(left, right)
}

const mul_bit256: Bitwise256Bytes = bitwise.mul_bits(hash256_field, True)

/// Multiplies a `Hash256` element by a ByteArray, interpreting bytes as a big-endian number.
pub fn mul_bytes(
  intermediate: State<Hash256>,
  bytes: ByteArray,
) -> State<Hash256> {
  mul_bit256(intermediate, bytes)
}

const mul_i256: Bitwise256Int = bitwise.mul_int(hash256_field)

/// Multiplies a `Hash256` element by an integer.
pub fn mul_int(intermediate: State<Hash256>, int: Int) -> State<Hash256> {
  mul_i256(intermediate, int)
}

const neg256: fn(State<Hash256>) -> State<Hash256> = bitwise.neg(hash256_field)

/// Calculates the additive inverse of a `Hash256` element.
pub fn neg(intermediate: State<Hash256>) -> State<Hash256> {
  neg256(intermediate)
}

const sub_s_hash256: Bitwise256State = bitwise.sub_state(hash256_field)

/// Subtracts one `Hash256` element from another, with the result wrapped within the finite field range.
pub fn sub(left: State<Hash256>, right: State<Hash256>) -> State<Hash256> {
  sub_s_hash256(left, right)
}

const sub_bit256: Bitwise256Bytes = bitwise.sub_bits(hash256_field, True)

/// Subtracts a ByteArray from a `Hash256` element, interpreting bytes as a big-endian number.
pub fn sub_bytes(
  intermediate: State<Hash256>,
  bytes: ByteArray,
) -> State<Hash256> {
  sub_bit256(intermediate, bytes)
}

const sub_i256: Bitwise256Int = bitwise.sub_int(hash256_field)

/// Subtracts an integer from a `Hash256` element.
pub fn sub_int(intermediate: State<Hash256>, int: Int) -> State<Hash256> {
  sub_i256(intermediate, int)
}

// ## Transforming

/// Converts a `Hash256` element back to its integer representation.
pub fn to_int(intermediate: State<Hash256>) -> Int {
  bitwise.to_int(intermediate)
}

/// Converts a `Hash256` element to a Big-Endian (most-significant bits first) `ByteArray`.
pub fn to_bytes(intermediate: State<Hash256>) -> ByteArray {
  bitwise.to_int(intermediate)
    |> builtin.integer_to_bytearray(True, field_size, _)
}

/// Converts a `Hash256` element to a Little-Endian (least-significant bits first) `ByteArray`.
pub fn to_bytes_little_endian(intermediate: State<Hash256>) -> ByteArray {
  bitwise.to_int(intermediate)
    |> builtin.integer_to_bytearray(False, field_size, _)
}
