// Rationals
// Authors:
// Micah Kendall
// <other authors go here>

pub type UncheckedRational {
  numerator: Int,
  denominator: Int,
}

pub opaque type Rational {
  numerator: Int,
  denominator: Int,
}

pub fn check_rational(num: UncheckedRational) -> Rational {
  let UncheckedRational { numerator, denominator } =
    num
  if denominator < 0 {
    Rational { numerator: -numerator, denominator: -denominator }
  } else {
    Rational { numerator, denominator }
  }
}

pub fn mul(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.numerator,
    denominator: a.denominator * b.denominator,
  }
}

pub fn div(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.denominator,
    denominator: a.denominator * b.numerator,
  }
}

pub fn div_int(a: Int, b: Int) -> Rational {
  Rational { numerator: a, denominator: b }
}

pub fn add(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.denominator + b.numerator * a.denominator,
    denominator: a.denominator * b.denominator,
  }
}

pub fn sub(a: Rational, b: Rational) -> Rational {
  Rational {
    numerator: a.numerator * b.denominator - b.numerator * a.denominator,
    denominator: a.denominator * b.denominator,
  }
}

pub fn gt(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator > b.numerator * a.denominator
}

pub fn lt(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator < b.numerator * a.denominator
}

pub fn ge(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator >= b.numerator * a.denominator
}

pub fn le(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator <= b.numerator * a.denominator
}

pub fn eq(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator == b.numerator * a.denominator
}

pub fn neq(a: Rational, b: Rational) -> Bool {
  a.numerator * b.denominator != b.numerator * a.denominator
}

pub fn from_int(a: Int) -> Rational {
  Rational { numerator: a, denominator: 1 }
}

pub fn truncate(a: Rational) -> Int {
  a.numerator / a.denominator
}
