/// The prime of the scalar field of the BLS12-381 curve.
pub const bls12_381_scalar_field_prime =
  52435875175126190479447740508185965837690552500527637822603658699938581184513

/// Opaque type used to ensure that a given integer is a valid element of the base field.
pub opaque type Scalar {
  integer: Int,
}

/// Creates a new Fp element from an integer.
pub fn newScalar(n: Int) -> Option<Scalar> {
  if n >= 0 && n < bls12_381_scalar_field_prime {
    Some(Scalar(n))
  } else {
    None
  }
}

test newScalar_1() {
  and {
    newScalar(-1) == None,
    newScalar(bls12_381_scalar_field_prime) == None,
    newScalar(834884848) == Some(Scalar(834884848)),
  }
}

/// Get the wrapped integer from an Fp element.
pub fn unScalar(self: Scalar) -> Int {
  self.integer
}

test unScalar_1() {
  unScalar(Scalar(834884848)) == 834884848
}

/// Add two Scalar elements.
pub fn add(left: Scalar, right: Scalar) -> Scalar {
  Scalar(( left.integer + right.integer ) % bls12_381_scalar_field_prime)
}

test add_1() {
  and {
    (add(Scalar(834884848), Scalar(834884848)) == Scalar(1669769696))?,
    (add(Scalar(bls12_381_scalar_field_prime - 1), Scalar(1)) == Scalar(0))?,
    (add(
      Scalar(3),
      Scalar(
        52435875175126190479447740508185965837690552500527637822603658699938581184513,
      ),
    ) == Scalar(3))?,
  }
}

pub fn sub(left: Scalar, right: Scalar) -> Scalar {
  Scalar(( left.integer - right.integer ) % bls12_381_scalar_field_prime)
}

test sub_1() {
  and {
    (sub(Scalar(834884848), Scalar(834884848)) == zero())?,
    (sub(zero(), Scalar(5)) == Scalar(bls12_381_scalar_field_prime - 5))?,
  }
}

/// A null `Scalar`.
pub fn zero() -> Scalar {
  Scalar(0)
}

test zero_1() {
  (zero() == Scalar(0))?
}

pub fn one() -> Scalar {
  Scalar(1)
}

test one_1() {
  one() == Scalar(1)
}

/// Negate a Scalar element.
pub fn neg(self: Scalar) -> Scalar {
  sub(zero(), self)
}

test neg_1() {
  and {
    neg(Scalar(834884848)) == Scalar(
      52435875175126190479447740508185965837690552500527637822603658699937746299665,
    ),
    neg(zero()) == zero(),
    neg(one()) == Scalar(bls12_381_scalar_field_prime - 1),
  }
}

/// Multiply two Scalar elements.
pub fn mul(left: Scalar, right: Scalar) -> Scalar {
  Scalar(left.integer * right.integer % bls12_381_scalar_field_prime)
}

test mul_1() {
  and {
    mul(Scalar(834884848), Scalar(834884848)) == Scalar(697032709419983104),
    mul(zero(), Scalar(834884848)) == zero(),
    mul(Scalar(bls12_381_scalar_field_prime - 1), Scalar(2)) == Scalar(
      52435875175126190479447740508185965837690552500527637822603658699938581184511,
    ),
  }
}

pub fn scale(self: Scalar, e: Int) -> Scalar {
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
    scale(Scalar(834884848), -1) == zero(),
    scale(Scalar(834884848), 0) == one(),
    scale(Scalar(834884848), 1) == Scalar(834884848),
    scale(Scalar(834884848), 2) == Scalar(697032709419983104),
    scale(Scalar(834884848), 3) == Scalar(581942047655130761945608192),
    scale(Scalar(bls12_381_scalar_field_prime - 4), 200) == Scalar(
      12843927705572658539565969578937286576443167978938369866871449552629978143484,
    ),
  }
}

fn helper_pow_of_two(self: Scalar, k: Int) -> Scalar {
  if k == 0 {
    self
  } else {
    helper_pow_of_two(mul(self, self), k - 1)
  }
}

pub fn pow_of_two(self: Scalar, k: Int) -> Scalar {
  if k < 0 {
    zero()
  } else {
    helper_pow_of_two(self, k)
  }
}

test pow_of_two_1() {
  and {
    pow_of_two(Scalar(834884848), -1) == zero(),
    pow_of_two(Scalar(834884848), 0) == scale(Scalar(834884848), 1),
    pow_of_two(Scalar(834884848), 1) == scale(Scalar(834884848), 2),
    pow_of_two(Scalar(834884848), 2) == scale(Scalar(834884848), 4),
    pow_of_two(Scalar(834884848), 3) == scale(Scalar(834884848), 8),
    pow_of_two(Scalar(834884848), 4) == scale(Scalar(834884848), 16),
  }
}

pub fn div(left: Scalar, right: Scalar) -> Option<Scalar> {
  if right == zero() {
    None
  } else {
    Some(mul(left, scale(right, bls12_381_scalar_field_prime - 2)))
  }
}

test div_1() {
  and {
    div(Scalar(834884848), Scalar(834884848)) == Some(Scalar(1)),
    div(Scalar(834884848), zero()) == None,
    div(Scalar(bls12_381_scalar_field_prime - 1), Scalar(2)) == Some(
      Scalar(
        26217937587563095239723870254092982918845276250263818911301829349969290592256,
      ),
    ),
  }
}

pub fn recip(self: Scalar) -> Option<Scalar> {
  div(one(), self)
}

test recip_1() {
  and {
    recip(Scalar(834884848)) == Some(
      Scalar(
        35891248691642227249400403463796410930702563777316955162085759263735363466421,
      ),
    ),
    recip(zero()) == None,
  }
}
