//// This module extends the finite field arithmetic to Fp2, a complexification of the finite field `Fp` associated with the BLS12-381 elliptic curve.
//// In Fp2, each element consists of two components, each being an element of Fp, representing a complex number where `i^2 = -1`.
////
//// The module provides functionality for basic arithmetic operations like addition, subtraction, multiplication, and division in this complex field. 
//// It also includes advanced operations such as exponentiation and computing multiplicative inverses in Fp2, extending the cryptographic capabilities of the BLS12-381 curve.

use aiken/bls12_381/fp

/// The type representing an element of the complexification of the finite field `Fp`.
pub type Fp2 {
  c0: fp.Fp,
  c1: fp.Fp,
}

/// Adds two `Fp2` elements, ensuring the result stays within the finite field range.
pub fn add(left: Fp2, right: Fp2) -> Fp2 {
  Fp2 { c0: fp.add(left.c0, right.c0), c1: fp.add(left.c1, right.c1) }
}

test add_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.zero() }
  let b = Fp2 { c0: fp.zero(), c1: fp.one() }
  let c = Fp2 { c0: fp.one(), c1: fp.one() }
  add(a, b) == c
}

/// Subtracts one `Fp2` element from another, with the result wrapped within the finite field range.
pub fn sub(left: Fp2, right: Fp2) -> Fp2 {
  Fp2 { c0: fp.sub(left.c0, right.c0), c1: fp.sub(left.c1, right.c1) }
}

test sub_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  let b = Fp2 { c0: fp.zero(), c1: fp.one() }
  let c = Fp2 { c0: fp.one(), c1: fp.zero() }
  sub(a, b) == c
}

/// Represents the additive identity (zero) in the `Fp2` field.
pub fn zero() -> Fp2 {
  Fp2 { c0: fp.zero(), c1: fp.zero() }
}

test zero_1() {
  zero() == Fp2 { c0: fp.zero(), c1: fp.zero() }
}

/// Represents the multiplicative identity (one) in the `Fp2` field.
pub fn one() -> Fp2 {
  Fp2 { c0: fp.one(), c1: fp.zero() }
}

test one_1() {
  one() == Fp2 { c0: fp.one(), c1: fp.zero() }
}

/// Calculates the additive inverse of a `Fp2` element.
pub fn neg(self: Fp2) -> Fp2 {
  Fp2 { c0: fp.neg(self.c0), c1: fp.neg(self.c1) }
}

test neg_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  let b = Fp2 { c0: fp.neg(fp.one()), c1: fp.neg(fp.one()) }
  neg(a) == b
}

/// Multiplies two `Fp2` elements, with the result constrained within the finite field.
pub fn mul(left: Fp2, right: Fp2) -> Fp2 {
  let ac = fp.mul(left.c0, right.c0)
  let bd = fp.mul(left.c1, right.c1)
  let ad = fp.mul(left.c0, right.c1)
  let bc = fp.mul(left.c1, right.c0)
  Fp2 { c0: fp.sub(ac, bd), c1: fp.add(ad, bc) }
}

test mul_1() {
  expect Some(d) = fp.new(2)
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  let b = Fp2 { c0: fp.one(), c1: fp.one() }
  let c = Fp2 { c0: fp.zero(), c1: d }
  mul(a, b) == c
}

/// Exponentiates an `Fp2` element by a non-negative integer exponent, using repeated squaring.
pub fn scale(self: Fp2, e: Int) -> Fp2 {
  if e < 0 {
    zero()
  } else if e == 0 {
    one()
  } else if e % 2 == 0 {
    scale(mul(self, self), e / 2)
  } else {
    mul(self, scale(mul(self, self), ( e - 1 ) / 2))
  }
}

test scale_1() {
  expect Some(d) = fp.new(2)
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  let b = Fp2 { c0: fp.zero(), c1: d }
  scale(a, 2) == b
}

/// Calculates the multiplicative inverse of an `Fp2` element, returning None if the element is zero.
pub fn recip(self: Fp2) -> Option<Fp2> {
  if self == zero() {
    None
  } else {
    let a = self.c0
    let b = self.c1
    let norm = fp.add(fp.mul(a, a), fp.mul(b, b))
    expect Some(x) = fp.div(a, norm)
    expect Some(y) = fp.div(fp.neg(b), norm)
    Some(Fp2 { c0: x, c1: y })
  }
}

test recip_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  expect Some(b0) =
    fp.new(
      2001204777610833696708894912867952078278441409969503942666029068062015825245418932221343814564507832018947136279894,
    )
  expect Some(b1) =
    fp.new(
      2001204777610833696708894912867952078278441409969503942666029068062015825245418932221343814564507832018947136279893,
    )
  expect Some(x) = recip(a)
  x == Fp2 { c0: b0, c1: b1 }
}

/// Divides one `Fp2` element by another, returning None if the divisor is zero.
pub fn div(left: Fp2, right: Fp2) -> Option<Fp2> {
  if right == zero() {
    None
  } else {
    expect Some(x) = recip(right)
    Some(mul(left, x))
  }
}

test div_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  div(a, a) == Some(one())
}

/// Verifies if the G2 generator of the BLS12-381 curve satisfies the complexification of the curve equation.
test generator_on_curve() {
  // The x.c0 coordinate of the G2 generator of the BLS12-381 curve.
  expect Some(x0) =
    fp.new(
      352701069587466618187139116011060144890029952792775240219908644239793785735715026873347600343865175952761926303160,
    )
  // The x.c1 coordinate of the G2 generator of the BLS12-381 curve.
  expect Some(x1) =
    fp.new(
      3059144344244213709971259814753781636986470325476647558659373206291635324768958432433509563104347017837885763365758,
    )
  // The y.c0 coordinate of the G2 generator of the BLS12-381 curve.
  expect Some(y0) =
    fp.new(
      1985150602287291935568054521177171638300868978215655730859378665066344726373823718423869104263333984641494340347905,
    )
  expect Some(y1) =
    fp.new(
      927553665492332455747201965776037880757740193453592970025027978793976877002675564980949289727957565575433344219582,
    )
  // in the complexification of the curve equation, y^2 = x^3 + 4, the constant becomes `4(1 + i) = 4 + 4i`.
  expect Some(four) = fp.new(4)
  let x = Fp2 { c0: x0, c1: x1 }
  let y = Fp2 { c0: y0, c1: y1 }
  let c = Fp2 { c0: four, c1: four }
  // Check that y^2 = x^3 + 4(1+i), the curve equation.
  mul(y, y) == add(mul(x, mul(x, x)), c)
}
