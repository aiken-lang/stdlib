use aiken/bls12_381/fp

pub type Fp2 {
  c0: fp.Fp,
  c1: fp.Fp,
}

pub fn add(left: Fp2, right: Fp2) -> Fp2 {
  Fp2 { c0: fp.add(left.c0, right.c0), c1: fp.add(left.c1, right.c1) }
}

test add_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.zero() }
  let b = Fp2 { c0: fp.zero(), c1: fp.one() }
  let c = Fp2 { c0: fp.one(), c1: fp.one() }
  add(a, b) == c
}

pub fn sub(left: Fp2, right: Fp2) -> Fp2 {
  Fp2 { c0: fp.sub(left.c0, right.c0), c1: fp.sub(left.c1, right.c1) }
}

test sub_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  let b = Fp2 { c0: fp.zero(), c1: fp.one() }
  let c = Fp2 { c0: fp.one(), c1: fp.zero() }
  sub(a, b) == c
}

pub fn zero() -> Fp2 {
  Fp2 { c0: fp.zero(), c1: fp.zero() }
}

test zero_1() {
  zero() == Fp2 { c0: fp.zero(), c1: fp.zero() }
}

pub fn one() -> Fp2 {
  Fp2 { c0: fp.one(), c1: fp.zero() }
}

test one_1() {
  one() == Fp2 { c0: fp.one(), c1: fp.zero() }
}

pub fn neg(self: Fp2) -> Fp2 {
  Fp2 { c0: fp.neg(self.c0), c1: fp.neg(self.c1) }
}

test neg_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  let b = Fp2 { c0: fp.neg(fp.one()), c1: fp.neg(fp.one()) }
  neg(a) == b
}

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

pub fn recip(self: Fp2) -> Fp2 {
  let a = self.c0
  let b = self.c1
  let norm = fp.add(fp.mul(a, a), fp.mul(b, b))
  expect Some(x) = fp.div(a, norm)
  expect Some(y) = fp.div(fp.neg(b), norm)
  Fp2 { c0: x, c1: y }
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
  recip(a) == Fp2 { c0: b0, c1: b1 }
}

pub fn div(left: Fp2, right: Fp2) -> Option<Fp2> {
  if right == zero() {
    None
  } else {
    Some(mul(left, recip(right)))
  }
}

test div_1() {
  let a = Fp2 { c0: fp.one(), c1: fp.one() }
  div(a, a) == Some(one())
}
