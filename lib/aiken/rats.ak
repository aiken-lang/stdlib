// Rationals
// Authors:
// Micah Kendall
// Ken Fritschy
// <other authors go here>

use aiken/math

// Useful for using Rationals in datums/redeemers which cannot have opaque types
pub type UncheckedRational {
  numerator: Int,
  denominator: Int,
}

// Opaque type used to ensure the sign of the Rational is managed strictly
// in the numerator
pub opaque type Rational {
  numerator: Int,
  denominator: Int,
}

// Converts an UncheckedRational to a Rational
pub fn check_rational(num: UncheckedRational) -> Rational {
  let UncheckedRational { numerator, denominator } =
    num
  div_int(numerator, denominator)
}

// Multiplication
pub fn mul(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.numerator,
    denominator: a.denominator * b.denominator,
  }
}

test mul_1() {
  let a =
    div_int(2, 3) |> mul(div_int(3, 4))
  a == Rational { numerator: 6, denominator: 12 }
}

test mul_2() {
  let a =
    div_int(-2, 3) |> mul(div_int(-3, 4))
  a == Rational { numerator: 6, denominator: 12 }
}

// Division
pub fn div(a: Rational, b: Rational) -> Rational {
  recip(b) |> mul(a)
}

test div_1() {
  let a =
    div_int(2, 3) |> div(div_int(3, 4))
  a == Rational { numerator: 8, denominator: 9 }
}

test div_2() {
  let a =
    div_int(2, 3) |> div(div_int(-3, 4))
  a == Rational { numerator: -8, denominator: 9 }
}

// Create a new Rational
pub fn div_int(numerator: Int, denominator: Int) -> Rational {
  if denominator < 0 {
    Rational { numerator: -numerator, denominator: -denominator }
  } else {
    Rational { numerator, denominator }
  }
}

test div_int_1() {
  div_int(2, 3) == Rational { numerator: 2, denominator: 3 }
}

test div_int_2() {
  div_int(-2, 3) == Rational { numerator: -2, denominator: 3 }
}

test div_int_3() {
  div_int(2, -3) == Rational { numerator: -2, denominator: 3 }
}

test div_int_4() {
  div_int(2, 4) == Rational { numerator: 2, denominator: 4 }
}

test div_int_5() {
  div_int(-2, -3) == Rational { numerator: 2, denominator: 3 }
}

test div_int_6() {
  div_int(-2, -4) == Rational { numerator: 2, denominator: 4 }
}

// Addition
pub fn add(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.denominator + b.numerator * a.denominator,
    denominator: a.denominator * b.denominator,
  }
}

test add_1() {
  let a =
    div_int(2, 3) |> add(div_int(3, 4))
  a == Rational { numerator: 17, denominator: 12 }
}

// Subtraction
pub fn sub(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.denominator - b.numerator * a.denominator,
    denominator: a.denominator * b.denominator,
  }
}

test sub_1() {
  let a =
    div_int(2, 3) |> sub(div_int(3, 4))
  a == Rational { numerator: -1, denominator: 12 }
}

// Greater than
pub fn gt(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator > b.numerator * a.denominator
}

test gt_1() {
  div_int(2, 3) |> gt(div_int(1, 3))
}

test gt_2() {
  let a =
    div_int(2, 3) |> gt(div_int(2, 3))
  a == False
}

// Less than
pub fn lt(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator < b.numerator * a.denominator
}

test lt_1() {
  div_int(2, 3) |> lt(div_int(3, 4))
}

test lt_2() {
  let a =
    div_int(2, 3) |> lt(div_int(2, 3))
  a == False
}

// Greater than or equal
pub fn ge(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator >= b.numerator * a.denominator
}

test ge_1() {
  div_int(2, 3) |> ge(div_int(1, 3))
}

test ge_2() {
  div_int(2, 3) |> ge(div_int(2, 3))
}

// Less than or equal
pub fn le(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator <= b.numerator * a.denominator
}

test le_1() {
  div_int(2, 3) |> le(div_int(3, 4))
}

test le_2() {
  div_int(2, 3) |> le(div_int(2, 3))
}

// Equal
pub fn eq(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator == b.numerator * a.denominator
}

test eq_1() {
  div_int(2, 3) |> eq(div_int(2, 3))
}

// Not Equal
pub fn neq(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator != b.numerator * a.denominator
}

test neq_1() {
  div_int(2, 3) |> neq(div_int(1, 3))
}

// Create a new Rational from an Int
pub fn from_int(a: Int) -> Rational {
  Rational { numerator: a, denominator: 1 }
}

test from_int_1() {
  from_int(3) == div_int(3, 1)
}

// Truncate a Rational to convert it to an Int
pub fn truncate(a: Rational) -> Int {
  a.numerator / a.denominator
}

test truncate_1() {
  let a =
    div_int(8, 3) |> truncate
  a == 2
}

// Change the sign of a Rational
pub fn neg(a: Rational) -> Rational {
  Rational { numerator: -a.numerator, denominator: a.denominator }
}

test neg_1() {
  let a =
    div_int(2, 3) |> neg
  a == Rational { numerator: -2, denominator: 3 }
}

// Absolute value of a Rational
pub fn abs(a: Rational) -> Rational {
  Rational { numerator: math.abs(a.numerator), denominator: a.denominator }
}

test abs_1() {
  let a =
    div_int(-2, 3) |> abs
  a == Rational { numerator: 2, denominator: 3 }
}

// Reciprocal of a Rational
pub fn recip(a: Rational) -> Rational {
  if a.numerator < 0 {
    Rational { numerator: -a.denominator, denominator: -a.numerator }
  } else if a.numerator > 0 {
    Rational { numerator: a.denominator, denominator: a.numerator }
  } else {
    error @"Denominator cannot be 0"
  }
}

test recip_1() {
  let a =
    div_int(2, 3) |> recip
  a == Rational { numerator: 3, denominator: 2 }
}

test recip_2() {
  let a =
    div_int(-2, 3) |> recip
  a == Rational { numerator: -3, denominator: 2 }
}

// Reduce a rational to its irreducible form
pub fn reduce(a: Rational) -> Rational {
  if a.denominator == 0 {
    error @"Denominator cannot be 0"
  } else {
    let d =
      gcd(a.numerator, a.denominator)
    Rational { numerator: a.numerator / d, denominator: a.denominator / d }
  }
}

test reduce_1() {
  let a =
    div_int(5040, 18018) |> reduce
  a == Rational { numerator: 40, denominator: 143 }
}

test reduce_2() {
  let a =
    div_int(-20, 4) |> reduce
  a == Rational { numerator: -5, denominator: 1 }
}

fn gcd(a: Int, b: Int) -> Int {
  do_gcd(math.abs(a), math.abs(b))
}

fn do_gcd(a: Int, b: Int) -> Int {
  if b == 0 {
    a
  } else {
    do_gcd(b, a % b)
  }
}
