//// This module implements arithmetic operations in the finite field Fp associated with the BLS12-381 elliptic curve. 
//// The BLS12-381 curve is defined by the equation `y^2 = x^3 + 4` over the field Fp, 
//// where p is a prime number. 
////
//// The elements of this finite field are the x and y coordinates of the points on the BLS12-381 curve.
////
//// Specifically, the prime p for the BLS12-381 curve's base field is defined as:
//// ```text
//// p = 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
//// ```
//// This module provides functionality to perform basic arithmetic operations (addition, subtraction, multiplication, division) and checks within this finite field context.

/// The prime number defining the base field of the BLS12-381 curve.
pub const bls12_381_base_field_prime =
  4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787

/// Opaque type representing an element of the finite field Fp. 
pub opaque type Fp {
  integer: Int,
}

/// Constructs a new Fp element from an integer, ensuring it's within the valid range of the field.
pub fn new(n: Int) -> Option<Fp> {
  if n >= 0 && n < bls12_381_base_field_prime {
    Some(Fp(n))
  } else {
    None
  }
}

test new_1() {
  and {
    new(-1) == None,
    new(bls12_381_base_field_prime) == None,
    new(834884848) == Some(Fp(834884848)),
  }
}

/// Converts an Fp element back to its integer representation.
pub fn to_int(self: Fp) -> Int {
  self.integer
}

test to_int_1() {
  to_int(Fp(834884848)) == 834884848
}

/// Adds two Fp elements, ensuring the result stays within the finite field range.
pub fn add(left: Fp, right: Fp) -> Fp {
  Fp(( left.integer + right.integer ) % bls12_381_base_field_prime)
}

test add_1() {
  and {
    add(Fp(834884848), Fp(834884848)) == Fp(1669769696),
    add(Fp(bls12_381_base_field_prime - 1), Fp(1)) == Fp(0),
  }
}

/// Subtracts one Fp element from another, with the result wrapped within the finite field range.
pub fn sub(left: Fp, right: Fp) -> Fp {
  Fp(( left.integer - right.integer ) % bls12_381_base_field_prime)
}

test sub_1() {
  and {
    sub(Fp(834884848), Fp(834884848)) == zero(),
    sub(zero(), Fp(1)) == Fp(bls12_381_base_field_prime - 1),
  }
}

/// Represents the additive identity (zero) in the Fp field.
pub fn zero() -> Fp {
  Fp(0)
}

/// Represents the multiplicative identity (one) in the Fp field.
pub fn one() -> Fp {
  Fp(1)
}

/// Calculates the additive inverse of an Fp element.
pub fn neg(self: Fp) -> Fp {
  sub(zero(), self)
}

test neg_1() {
  and {
    neg(Fp(834884848)) == Fp(
      4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037893437674939,
    ),
    neg(zero()) == zero(),
    neg(one()) == Fp(bls12_381_base_field_prime - 1),
  }
}

/// Multiplies two Fp elements, with the result constrained within the finite field./// Multiplies two Fp elements, with the result constrained within the finite field.
pub fn mul(left: Fp, right: Fp) -> Fp {
  Fp(left.integer * right.integer % bls12_381_base_field_prime)
}

test mul_1() {
  and {
    mul(Fp(834884848), Fp(834884848)) == Fp(697032709419983104),
    mul(Fp(834884848), zero()) == zero(),
    mul(Fp(bls12_381_base_field_prime - 1), Fp(2)) == Fp(
      4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559785,
    ),
  }
}

/// Exponentiates an Fp element by a non-negative integer exponent, using repeated squaring.
pub fn scale(self: Fp, e: Int) -> Fp {
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
  and {
    scale(Fp(834884848), -1) == zero(),
    scale(Fp(834884848), 0) == Fp(1),
    scale(Fp(834884848), 1) == Fp(834884848),
    scale(Fp(834884848), 2) == Fp(697032709419983104),
    scale(Fp(834884848), 3) == Fp(581942047655130761945608192),
    scale(Fp(bls12_381_base_field_prime - 4), 200) == Fp(
      3298115879772442383456763501381931432033240713978427319412683097749974715857113563247532083408421582810462532035225,
    ),
  }
}

/// Divides one Fp element by another, returning None if the divisor is zero.
pub fn div(left: Fp, right: Fp) -> Option<Fp> {
  if right == zero() {
    None
  } else {
    Some(mul(left, scale(right, bls12_381_base_field_prime - 2)))
  }
}

test div_1() {
  and {
    div(Fp(834884848), Fp(834884848)) == Some(Fp(1)),
    div(Fp(834884848), zero()) == None,
    div(Fp(bls12_381_base_field_prime - 1), Fp(2)) == Some(
      Fp(
        2001204777610833696708894912867952078278441409969503942666029068062015825245418932221343814564507832018947136279893,
      ),
    ),
  }
}

/// Calculates the multiplicative inverse of an Fp element, returning None if the element is zero.
pub fn recip(self: Fp) -> Option<Fp> {
  div(one(), self)
}

test recip_1() {
  and {
    recip(Fp(834884848)) == Some(
      Fp(
        3684670845189863184374038366997560422126518215612822328820436191640781467884602405023538183052843227498556212782997,
      ),
    ),
    recip(zero()) == None,
  }
}

/// Verifies if the G1 generator of the BLS12-381 curve satisfies the curve equation.
test generator_on_curve() {
  // The x coordinate of the G1 generator of the BLS12-381 curve.
  expect Some(x) =
    new(
      3685416753713387016781088315183077757961620795782546409894578378688607592378376318836054947676345821548104185464507,
    )
  // The y coordinate of the G1 generator of the BLS12-381 curve.
  expect Some(y) =
    new(
      1339506544944476473020471379941921221584933875938349620426543736416511423956333506472724655353366534992391756441569,
    )
  expect Some(four) = new(4)
  // Check that y^2 = x^3 + 4, the curve equation.
  mul(y, y) == add(mul(x, mul(x, x)), four)
}
