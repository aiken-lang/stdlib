/// The prime of the base field of the BLS12-381 curve.
pub const bls12_381_base_field_prime =
  4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787

/// Opaque type used to ensure that a given integer is a valid element of the base field.
pub opaque type Fp {
  integer: Int,
}

/// Creates a new Fp element from an integer.
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

/// Get the wrapped integer from an Fp element.
pub fn unFp(self: Fp) -> Int {
  self.integer
}

test unFp_1() {
  unFp(Fp(834884848)) == 834884848
}

/// Add two Fp elements.
pub fn add(left: Fp, right: Fp) -> Fp {
  Fp(( left.integer + right.integer ) % bls12_381_base_field_prime)
}

test add_1() {
  and {
    add(Fp(834884848), Fp(834884848)) == Fp(1669769696),
    add(Fp(bls12_381_base_field_prime - 1), Fp(1)) == Fp(0),
  }
}

/// Subtract two Fp elements.
pub fn sub(left: Fp, right: Fp) -> Fp {
  Fp(( left.integer - right.integer ) % bls12_381_base_field_prime)
}

test sub_1() {
  and {
    sub(Fp(834884848), Fp(834884848)) == zero(),
    sub(zero(), Fp(1)) == Fp(bls12_381_base_field_prime - 1),
  }
}

/// A null `Fp`.
pub fn zero() -> Fp {
  Fp(0)
}

test zero_1() {
  zero() == Fp(0)
}

pub fn one() -> Fp {
  Fp(1)
}

test one_1() {
  one() == Fp(1)
}

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

/// Multiply two Fp elements.
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
