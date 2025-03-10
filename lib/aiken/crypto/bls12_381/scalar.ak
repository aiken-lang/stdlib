//// This module implements arithmetic operations in the scalar field associated with the BLS12-381 elliptic curve.
//// The scalar field, defined over a prime number `q`, is derived from the order of the subgroup G1.
////
//// More explicitly, we have the identity:
////
//// ```aiken
//// builtin.bls12_381_g1_scalar_mul(q, bls12_381_g1_generator) == 1
//// ```
////
//// where,
////
//// ```aiken
//// q = 52435875175126190479447740508185965837690552500527637822603658699938581184513
//// ```
////
//// This module provides functionality for basic arithmetic operations (addition, subtraction, multiplication, division) within this scalar field.
//// Additionally, it includes advanced operations such as exponentiation and calculation of multiplicative inverses, tailored for cryptographic applications.

use aiken/builtin
use aiken/crypto/bitwise.{State, one, zero}

/// The prime number defining the scalar field of the BLS12-381 curve.
pub const field_prime =
  52435875175126190479447740508185965837690552500527637822603658699938581184513

pub const field_size = 32

pub type Scalar =
  ByteArray

test field_prime_1() {
  builtin.integer_to_bytearray(True, 32, field_prime) == #"73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001"
}

// ## Constructing
/// Constructs a new `Scalar` element from a Big-Endian (most-significant bits first) `ByteArray`.
pub fn from_bytes(b: ByteArray) -> State<Scalar> {
  b
    |> builtin.bytearray_to_integer(True, _)
    |> bitwise.from_int(field_prime)
}

/// Constructs a new `Scalar` element from a Little-Endian (least-significant bits first) `ByteArray`.
pub fn from_bytes_little_endian(bytes: ByteArray) -> State<Scalar> {
  bytes
    |> builtin.bytearray_to_integer(False, _)
    |> bitwise.from_int(field_prime)
}

/// Constructs a new `Scalar` element from an integer, ensuring it's within the valid range of the field.
pub fn from_int(n: Int) -> State<Scalar> {
  bitwise.from_int(n, field_prime)
}

test new_1() {
  trace from_int(-1)
  and {
    ( from_int(-1) |> to_int ) == field_prime - 1,
    ( from_int(field_prime) |> to_int ) == 0,
    ( from_int(834884848) |> to_int ) == 834884848,
  }
}

test from_bytearray_big_endian_1() {
  ( from_bytes(#"ffff00") |> to_int ) == 16776960
}

test from_bytearray_little_endian_1() {
  ( from_bytes_little_endian(#"ffff00") |> to_int ) == 65535
}

type BitwiseScalarBytes =
  fn(State<Scalar>, ByteArray) -> State<Scalar>

type BitwiseScalarInt =
  fn(State<Scalar>, Int) -> State<Scalar>

type BitwiseScalarState =
  fn(State<Scalar>, State<Scalar>) -> State<Scalar>

// ## Modifying

/// Exponentiates an `Scalar` element by a non-negative integer exponent, using repeated squaring.
/// Note that this function returns `scalar.zero` for negative exponents.
/// A dedicated builtin function for this is in the making, see CIP 109.
pub fn scale(self: State<Scalar>, e: Int) -> State<Scalar> {
  bitwise.scale(self, e, mul)
}

test scale_1() {
  let x = from_int(834884848)

  and {
    ( x |> scale(-1) ) == zero,
    ( x |> scale(0) ) == one,
    ( x |> scale(1) ) == x,
    ( x |> scale(2) |> to_int ) == 697032709419983104,
    ( x |> scale(3) |> to_int ) == 581942047655130761945608192,
    (
      from_int(field_prime - 4)
        |> scale(200)
        |> to_int
    ) == 12843927705572658539565969578937286576443167978938369866871449552629978143484,
  }
}

/// A faster version of `scale` for the case where the exponent is a power of two.
/// That is, the exponent `e = 2^k` for some non-negative integer `k`. Which is used alot in zk-SNARKs.
pub fn scale2(self: State<Scalar>, k: Int) -> State<Scalar> {
  bitwise.scale2(self, k, mul)
}

test scale2_1() {
  let x = from_int(834884848)

  and {
    scale2(x, -1) == zero,
    scale2(x, 0) == scale(x, 1),
    scale2(x, 1) == scale(x, 2),
    scale2(x, 2) == scale(x, 4),
    scale2(x, 3) == scale(x, 8),
    scale2(x, 4) == scale(x, 16),
  }
}

// ## Combining

const add_s_scalar: BitwiseScalarState = bitwise.add_state(field_prime)

/// Adds two `Scalar` elements, ensuring the result stays within the finite field range.
pub fn add(left: State<Scalar>, right: State<Scalar>) -> State<Scalar> {
  add_s_scalar(left, right)
}

const add_bit_scalar: BitwiseScalarBytes = bitwise.add_bits(field_prime, True)

pub fn add_bytes(intermediate: State<Scalar>, bytes: ByteArray) -> State<Scalar> {
  add_bit_scalar(intermediate, bytes)
}

const add_i_scalar: BitwiseScalarInt = bitwise.add_int(field_prime)

pub fn add_int(intermediate: State<Scalar>, int: Int) -> State<Scalar> {
  add_i_scalar(intermediate, int)
}

test add_1() {
  let x = from_int(834884848)
  let y = from_int(field_prime - 1)
  let z = from_int(3)

  and {
    (( add(x, x) |> to_int ) == 1669769696)?,
    (add(y, one) == zero)?,
    (add(z, add(y, one)) == z)?,
  }
}

/// Divides one `Scalar` element by another, returning `None` if the divisor is zero.
pub fn div(left: State<Scalar>, right: State<Scalar>) -> Option<State<Scalar>> {
  if right == zero {
    None
  } else {
    Some(mul(left, scale(right, field_prime - 2)))
  }
}

pub fn div_int(left: State<Scalar>, right: Int) -> Option<State<Scalar>> {
  let right = from_int(right)
  if right == zero {
    None
  } else {
    Some(mul(left, scale(right, field_prime - 2)))
  }
}

pub fn div_bytes(left: State<Scalar>, right: ByteArray) -> Option<State<Scalar>> {
  let right = from_bytes(right)

  if right == zero {
    None
  } else {
    Some(mul(left, scale(right, field_prime - 2)))
  }
}

test div_1() {
  let x = from_int(834884848)

  and {
    div(x, x) == Some(one),
    div(x, zero) == None,
    div(from_int(field_prime - 1), from_int(2)) == Some(
      from_int(
        26217937587563095239723870254092982918845276250263818911301829349969290592256,
      ),
    ),
  }
}

const mul_s_scalar: BitwiseScalarState = bitwise.mul_state(field_prime)

/// Multiplies two `Scalar` elements, with the result constrained within the finite field.
pub fn mul(left: State<Scalar>, right: State<Scalar>) -> State<Scalar> {
  mul_s_scalar(left, right)
}

const mul_bit_scalar: BitwiseScalarBytes = bitwise.mul_bits(field_prime, True)

pub fn mul_bytes(intermediate: State<Scalar>, bytes: ByteArray) -> State<Scalar> {
  mul_bit_scalar(intermediate, bytes)
}

const mul_i_scalar: BitwiseScalarInt = bitwise.mul_int(field_prime)

pub fn mul_int(intermediate: State<Scalar>, int: Int) -> State<Scalar> {
  mul_i_scalar(intermediate, int)
}

test mul_1() {
  let x = from_int(834884848)
  and {
    mul(x, x) == from_int(697032709419983104),
    mul(zero, x) == zero,
    mul(from_int(field_prime - 1), from_int(2)) == from_int(
      52435875175126190479447740508185965837690552500527637822603658699938581184511,
    ),
  }
}

const neg_scalar: fn(State<Scalar>) -> State<Scalar> = bitwise.neg(field_prime)

/// Calculates the additive inverse of a `Scalar` element.
pub fn neg(intermediate: State<Scalar>) -> State<Scalar> {
  neg_scalar(intermediate)
}

test neg_1() {
  trace neg(zero)

  and {
    neg(from_int(834884848)) == from_int(
      52435875175126190479447740508185965837690552500527637822603658699937746299665,
    ),
    neg(zero) == zero,
    neg(one) == from_int(field_prime - 1),
  }
}

/// Calculates the multiplicative inverse of an `Scalar` element, returning `None` if the element is zero.
pub fn recip(self: State<Scalar>) -> Option<State<Scalar>> {
  div(one, self)
}

test recip_1() {
  and {
    recip(from_int(834884848)) == Some(
      from_int(
        35891248691642227249400403463796410930702563777316955162085759263735363466421,
      ),
    ),
    recip(zero) == None,
  }
}

const sub_s_scalar: BitwiseScalarState = bitwise.sub_state(field_prime)

/// Subtracts one `Scalar` element from another, with the result wrapped within the finite field range.
pub fn sub(left: State<Scalar>, right: State<Scalar>) -> State<Scalar> {
  sub_s_scalar(left, right)
}

const sub_bit_scalar: BitwiseScalarBytes = bitwise.sub_bits(field_prime, True)

pub fn sub_bytes(intermediate: State<Scalar>, bytes: ByteArray) -> State<Scalar> {
  sub_bit_scalar(intermediate, bytes)
}

const sub_i_scalar: BitwiseScalarInt = bitwise.sub_int(field_prime)

pub fn sub_int(intermediate: State<Scalar>, int: Int) -> State<Scalar> {
  sub_i_scalar(intermediate, int)
}

test sub_1() {
  let x = from_int(834884848)

  and {
    (sub(x, x) == zero)?,
    (sub(zero, from_int(5)) == from_int(field_prime - 5))?,
  }
}

// ## Transforming

/// Converts a `Scalar` element back to its integer representation.
pub fn to_int(s: State<Scalar>) -> Int {
  bitwise.to_int(s)
}

/// Converts a `Scalar` element to a Big-Endian (most-significant bits first) `ByteArray`.
pub fn to_bytes(s: State<Scalar>) -> ByteArray {
  s |> bitwise.to_int |> builtin.integer_to_bytearray(True, field_size, _)
}

/// Converts a `Scalar` element to a Little-Endian (least-significant bits first) `ByteArray`.
pub fn to_bytes_little_endian(s: State<Scalar>) -> ByteArray {
  s |> bitwise.to_int |> builtin.integer_to_bytearray(False, field_size, _)
}

test to_int_1() {
  to_int(from_int(834884848)) == 834884848
}

test to_bytearray_1() {
  ( to_bytes(from_int(16777215)) |> builtin.slice_bytearray(29, 32, _) ) == #"ffffff"
}
