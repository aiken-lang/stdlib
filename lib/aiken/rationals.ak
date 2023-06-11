//// Rationals

// todo: more comments (good docs)
//      finish compare tests

use aiken/math
use aiken/option

/// Useful for using Rationals in datums/redeemers which cannot have opaque types.
/// 
/// Use **check_rational** or **unsafe_check_rational** to convert to a Rational.
pub type UncheckedRational {
  numerator: Int,
  denominator: Int,
}

/// Opaque type used to ensure the sign of the Rational is managed strictly in the numerator.
pub opaque type Rational {
  numerator: Int,
  denominator: Int,
}

/// Converts an UncheckedRational to a Rational
///
/// ```aiken
/// check_rational(UncheckedRational { numerator: 2, denominator: 3 }) == Some(Rational { numerator: 2, denominator: 3 })
/// ```
pub fn check_rational(num: UncheckedRational) -> Option<Rational> {
  let UncheckedRational { numerator, denominator } = num
  div_int(numerator, denominator)
}

/// Unsafely converts an UncheckedRational to a Rational
///
/// ```aiken
/// unsafe_check_rational(UncheckedRational { numerator: 2, denominator: 3 }) == Rational { numerator: 2, denominator: 3 }
/// ```
pub fn unsafe_check_rational(num: UncheckedRational) -> Rational {
  let UncheckedRational { numerator, denominator } = num
  unsafe_div_int(numerator, denominator)
}

/// Multiplication
/// product of two rational values
/// ```aiken
/// mul(Rational { numerator: x, denominator: y }, Rational { numerator: a, denominator: b }) == Rational { numerator: x*a, denominator: y*b }
/// ```
pub fn mul(a: Rational, b: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  Rational { numerator: a_n * b_n, denominator: a_d * b_d }
}

test mul_1() {
  ( unsafe_div_int(2, 3) |> mul(unsafe_div_int(3, 4)) ) == Rational {
    numerator: 6,
    denominator: 12,
  }
}

test mul_2() {
  ( unsafe_div_int(-2, 3) |> mul(unsafe_div_int(-3, 4)) ) == Rational {
    numerator: 6,
    denominator: 12,
  }
}

/// Division
/// quotient of two rational values
/// none if the second value is 0
/// ```aiken
/// div(Rational { numerator: x, denominator: y }, Rational { numerator: a, denominator: b }) == Rational { numerator: x*b, denominator: y*a }
/// ```
pub fn div(a: Rational, b: Rational) -> Option<Rational> {
  recip(b) |> option.map(fn(x) { x |> mul(a) })
}

/// Unsafe division
/// quotient of two rational values
/// panics if the second value is 0 (unsafe)
/// ```aiken
/// unsafe_div_int(x, y) |> unsafe_div(unsafe_div_int(a, b)) == Rational { numerator: x*b, denominator: y*a }
/// ```
pub fn unsafe_div(a: Rational, b: Rational) -> Rational {
  unsafe_recip(b) |> mul(a)
}

test div_1() {
  ( unsafe_div_int(2, 3) |> unsafe_div(unsafe_div_int(3, 4)) ) == Rational {
    numerator: 8,
    denominator: 9,
  }
}

test div_2() {
  ( unsafe_div_int(2, 3) |> unsafe_div(unsafe_div_int(-3, 4)) ) == Rational {
    numerator: -8,
    denominator: 9,
  }
}

/// Division of integers, giving a rational
/// quotient of two integers
/// none if the second value is 0
/// ```aiken
/// div_int(x, 0) == None
/// div_int(x, y) == Some(Rational { numerator: x, denominator: y })
/// ```
pub fn div_int(numerator: Int, denominator: Int) -> Option<Rational> {
  if denominator == 0 {
    None
  } else if denominator < 0 {
    Some(Rational { numerator: -numerator, denominator: -denominator })
  } else {
    Some(Rational { numerator, denominator })
  }
}

test div_int_byzero() {
  div_int(2, 0) == None
}

test div_int_1() {
  div_int(2, 3) == Some(Rational { numerator: 2, denominator: 3 })
}

test div_int_2() {
  div_int(-2, 3) == Some(Rational { numerator: -2, denominator: 3 })
}

test div_int_3() {
  div_int(2, -3) == Some(Rational { numerator: -2, denominator: 3 })
}

test div_int_4() {
  div_int(2, 4) == Some(Rational { numerator: 2, denominator: 4 })
}

test div_int_5() {
  div_int(-2, -3) == Some(Rational { numerator: 2, denominator: 3 })
}

test div_int_6() {
  div_int(-2, -4) == Some(Rational { numerator: 2, denominator: 4 })
}

/// Create a new Rational
/// quotient of two integers
/// panics if the second value is 0 (unsafe)
/// ```aiken
/// unsafe_div_int(x, y) == Rational { numerator: x, denominator: y }
/// unsafe_div_int(x, 0) == error
/// ```
pub fn unsafe_div_int(numerator: Int, denominator: Int) -> Rational {
  if denominator == 0 {
    error @"Division by 0"
  } else if denominator < 0 {
    Rational { numerator: -numerator, denominator: -denominator }
  } else {
    Rational { numerator, denominator }
  }
}

test unsafe_div_int_1() {
  unsafe_div_int(2, 3) == Rational { numerator: 2, denominator: 3 }
}

test unsafe_div_int_2() {
  unsafe_div_int(-2, 3) == Rational { numerator: -2, denominator: 3 }
}

test unsafe_div_int_3() {
  unsafe_div_int(2, -3) == Rational { numerator: -2, denominator: 3 }
}

test unsafe_div_int_4() {
  unsafe_div_int(2, 4) == Rational { numerator: 2, denominator: 4 }
}

test unsafe_div_int_5() {
  unsafe_div_int(-2, -3) == Rational { numerator: 2, denominator: 3 }
}

test unsafe_div_int_6() {
  unsafe_div_int(-2, -4) == Rational { numerator: 2, denominator: 4 }
}

/// Addition
/// sum of two rational values
/// ```aiken
/// add(Rational { numerator: x, denominator: y }, Rational { numerator: a, denominator: b }) == Rational { numerator: x*b + a*y, denominator: y*b }
/// ```
pub fn add(a: Rational, b: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  Rational { numerator: a_n * b_d + b_n * a_d, denominator: a_d * b_d }
}

test add_1() {
  ( unsafe_div_int(2, 3) |> add(unsafe_div_int(3, 4)) ) == Rational {
    numerator: 17,
    denominator: 12,
  }
}

/// Subtraction
/// difference of two rational values
/// ```aiken
/// unsafe_div_int(x, y) |> sub(unsafe_div_int(a, b)) == Rational { numerator: x*b - a*y, denominator: y*b }
/// ```
pub fn sub(a: Rational, b: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  Rational { numerator: a_n * b_d - b_n * a_d, denominator: a_d * b_d }
}

test sub_1() {
  ( unsafe_div_int(2, 3) |> sub(unsafe_div_int(3, 4)) ) == Rational {
    numerator: -1,
    denominator: 12,
  }
}

/// Greater than
/// ```aiken
/// gt(Rational { numerator: 5, denominator: 7 }, Rational { numerator: 5, denominator: 6 }) == False
/// gt(Rational (5, 6), Rational (5, 7)) == True
/// ```
pub fn gt(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d > b_n * a_d
}

test gt_1() {
  unsafe_div_int(2, 3) |> gt(unsafe_div_int(1, 3))
}

test gt_2() {
  ( unsafe_div_int(2, 3) |> gt(unsafe_div_int(2, 3)) ) == False
}

/// Less than
/// ```aiken
/// lt(Rational { numerator: 5, denominator: 7 }, Rational { numerator: 5, denominator: 6 }) == True
/// lt(Rational (5, 6), Rational (5, 7)) == False
/// ```
pub fn lt(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d < b_n * a_d
}

test lt_1() {
  unsafe_div_int(2, 3) |> lt(unsafe_div_int(3, 4))
}

test lt_2() {
  ( unsafe_div_int(2, 3) |> lt(unsafe_div_int(2, 3)) ) == False
}

/// Greater than or equal
/// ```aiken
/// ge(Rational { numerator: 5, denominator: 7 }, Rational { numerator: 5, denominator: 6 }) == False
/// ge(Rational (5, 6), Rational (5, 7)) == True
/// ge(Rational (5, 6), Rational (5, 6)) == True
/// ```
pub fn ge(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d >= b_n * a_d
}

test ge_1() {
  unsafe_div_int(2, 3) |> ge(unsafe_div_int(1, 3))
}

test ge_2() {
  unsafe_div_int(2, 3) |> ge(unsafe_div_int(2, 3))
}

/// Less than or equal
/// ```aiken
/// le(Rational { numerator: 5, denominator: 7 }, Rational { numerator: 5, denominator: 6 }) == True
/// le(Rational (5, 6), Rational (5, 7)) == False
/// le(Rational (5, 6), Rational (5, 6)) == True
/// ```
pub fn le(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d <= b_n * a_d
}

test le_1() {
  unsafe_div_int(2, 3) |> le(unsafe_div_int(3, 4))
}

test le_2() {
  unsafe_div_int(2, 3) |> le(unsafe_div_int(2, 3))
}

/// Equal
/// ```aiken
/// eq(Rational { numerator: 5, denominator: 7 }, Rational { numerator: 5, denominator: 6 }) == False
/// eq(Rational (5, 6), Rational (5, 7)) == False
/// eq(Rational (5, 6), Rational (5, 6)) == True
/// ```
pub fn eq(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d == b_n * a_d
}

test eq_1() {
  unsafe_div_int(2, 3) |> eq(unsafe_div_int(2, 3))
}

/// Not Equal
/// ```aiken
/// neq(Rational { numerator: 5, denominator: 7 }, Rational { numerator: 5, denominator: 6 }) == True
/// neq(Rational (5, 6), Rational (5, 7)) == True
/// unsafe_div_int(5, 6) |> neq(Rational(5,7)) == True
/// ```
pub fn neq(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d != b_n * a_d
}

test neq_1() {
  unsafe_div_int(2, 3) |> neq(unsafe_div_int(1, 3))
}

/// Create a new Rational from an Int
/// ```aiken
/// from_int(-5) == Rational { numerator: -5, denominator: 1 }
/// from_int(3) == Rational { numerator: 3, denominator: 1 }
/// from_int(0) == Rational { numerator: 0, denominator: 1 }
/// ```
pub fn from_int(a: Int) -> Rational {
  Rational { numerator: a, denominator: 1 }
}

test from_int_1() {
  from_int(3) == unsafe_div_int(3, 1)
}

/// Truncate a Rational to convert it to an Int
/// ```aiken
/// truncate(unsafe_div_int(5, 2)) == 2
/// truncate(unsafe_div_int(5, 3)) == 1
/// truncate(unsafe_div_int(5, 4)) == 1
/// truncate(unsafe_div_int(5, 5)) == 1
/// truncate(unsafe_div_int(5, 6)) == 0
/// ```
pub fn truncate(a: Rational) -> Int {
  let Rational { numerator: a_n, denominator: a_d } = a
  a_n / a_d
}

test truncate_1() {
  ( unsafe_div_int(8, 3) |> truncate ) == 2
}

/// Change the sign of a Rational
/// ```aiken
/// neg(Rational { numerator: 5, denominator: 2 }) == Rational { numerator: -5, denominator: 2 }
/// neg(Rational { numerator: -5, denominator: 2 }) == Rational { numerator: 5, denominator: 2 }
/// ```
pub fn neg(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  Rational { numerator: -a_n, denominator: a_d }
}

test neg_1() {
  ( unsafe_div_int(2, 3) |> neg ) == Rational { numerator: -2, denominator: 3 }
}

/// Absolute value of a Rational
/// ```aiken
/// abs(Rational { numerator: 5, denominator: 2 }) == Rational { numerator: 5, denominator: 2 }
/// abs(Rational { numerator: -5, denominator: 2 }) == Rational { numerator: 5, denominator: 2 }
/// ```
pub fn abs(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  Rational { numerator: math.abs(a_n), denominator: a_d }
}

test abs_1() {
  ( unsafe_div_int(-2, 3) |> abs ) == Rational { numerator: 2, denominator: 3 }
}

/// Reciprocal of a Rational
/// ```aiken
/// unsafe_div_int(5, 2) |> recip() == Some(Rational { numerator: 2, denominator: 5 })
/// unsafe_div_int(-5, 2) |> recip() == Some(Rational { numerator: -2, denominator: 5 })
/// unsafe_div_int(0, 2) |> recip() == None
/// ```
pub fn recip(a: Rational) -> Option<Rational> {
  let Rational { numerator: a_n, denominator: a_d } = a
  if a_n < 0 {
    Some(Rational { numerator: -a_d, denominator: -a_n })
  } else if a_n > 0 {
    Some(Rational { numerator: a_d, denominator: a_n })
  } else {
    None
  }
}

test recip_1() {
  ( div_int(2, 3) |> option.map(recip) ) == Some(div_int(3, 2))
}

test recip_2() {
  ( div_int(-2, 3) |> option.map(recip) ) == Some(div_int(-3, 2))
}

/// Reciprocal of a Rational (unsafe)
/// ```aiken
/// unsafe_div_int(5, 2) |> unsafe_recip() == Rational { numerator: 2, denominator: 5 }
/// unsafe_div_int(-6, 7) |> unsafe_recip() == Rational { numerator: -7, denominator: 6 }
/// unsafe_div_int(0, 2) |> unsafe_recip() == error
/// ```
pub fn unsafe_recip(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  if a_n < 0 {
    Rational { numerator: -a_d, denominator: -a_n }
  } else if a_n > 0 {
    Rational { numerator: a_d, denominator: a_n }
  } else {
    error @"Denominator cannot be 0"
  }
}

test unsafe_recip_1() {
  ( div_int(2, 3) |> option.map(unsafe_recip) ) == div_int(3, 2)
}

test unsafe_recip_2() {
  ( div_int(-2, 3) |> option.map(unsafe_recip) ) == div_int(-3, 2)
}

/// Reduce a rational to its irreducible form
/// ```aiken
/// div_int(80, 200) |> option.map(reduce) == Some(Rational { numerator: 2, denominator: 5 })
/// div_(-5, 1) |> option.map(reduce) == Some(Rational { numerator: -5, denominator: 1 })
/// ```
pub fn reduce(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let d = math.gcd(a_n, a_d)
  Rational { numerator: a_n / d, denominator: a_d / d }
}

test reduce_1() {
  ( div_int(5040, 18018) |> option.map(reduce) ) == div_int(40, 143)
}

test reduce_2() {
  ( div_int(-20, 4) |> option.map(reduce) ) == div_int(-5, 1)
}

/// Compare two rationals for an ordering
/// ```aiken
/// div_int(5, 2) |> option.map(compare(_, unsafe_div_int(5, 2))) == Some(Equal)
/// div_int(5, 2) |> option.map(compare(_, Rational { numerator: 10, denominator: 4 })) == Some(Equal)
/// compare(Rational { numerator: 5, denominator: 2 }, Rational { numerator: 5, denominator: 3 }) == Greater
/// unsafe_div_int(5, 2) |> compare(Rational { numerator: 5, denominator: 1 }) == Less
/// ```
pub fn compare(left: Rational, right: Rational) -> Ordering {
  if left |> lt(right) {
    Less
  } else if left |> gt(right) {
    Greater
  } else {
    Equal
  }
}

test compare_1() {
  ( div_int(3, 8) |> option.map(compare(_, unsafe_div_int(-2, 4))) ) == Some(
    Greater,
  )
}

test compare_2() {
  ( unsafe_div_int(3, 8) |> compare(unsafe_div_int(2, 4)) ) == Less
}

test compare_3() {
  ( unsafe_div_int(3, 8) |> compare(unsafe_div_int(3, 8)) ) == Equal
}
