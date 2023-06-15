//// This module implements operations between data structures of type Rational.
////
//// Rational numbers are represented as a pair of integers, a numerator and a denominator.
////
//// - the denominator is always positive
//// - the sign is managed in the numerator.
//// - the denominator is never 0.
//// - the numerator and denominator are not implicitly reduced. This is done on demand.
////
//// Reducing should be done before write (e.g validating datum output)

// todo: more comments (good docs)
//      finish compare tests

use aiken/math
use aiken/option

/// Opaque type used to ensure the sign of the Rational is managed strictly in the numerator.
pub opaque type Rational {
  numerator: Int,
  denominator: Int,
}

/// Multiplication
/// product of two rational values
/// ```aiken
/// mul(new(x, y), new(a, b)) == new ( x*a, y*b )
/// ```
pub fn mul(a: Rational, b: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  Rational { numerator: a_n * b_n, denominator: a_d * b_d }
}

test mul_1() {
  ( expect_new(2, 3) |> mul(expect_new(3, 4)) ) == Rational {
    numerator: 6,
    denominator: 12,
  }
}

test mul_2() {
  ( expect_new(-2, 3) |> mul(expect_new(-3, 4)) ) == Rational {
    numerator: 6,
    denominator: 12,
  }
}

test mul_3() {
  (
    expect_new(2, 5)
      |> mul(expect_new(1, 8))
      |> mul(expect_new(3, 10))
      |> mul(expect_new(21, 100))
      |> mul(expect_new(3, 5))
      |> mul(expect_new(2, 8))
      |> mul(expect_new(4, 10))
      |> mul(expect_new(22, 100))
      |> reduce()
  ) == Rational { numerator: 2079, denominator: 50000000 }
}

/// Division
/// quotient of two rational values
/// none if the second value is 0
/// ```aiken
/// div(new(x, y), new(a, b)) == new ( x*b, y*a )
/// ```
pub fn div(a: Rational, b: Rational) -> Option<Rational> {
  recip(b) |> option.map(fn(x) { x |> mul(a) })
}

/// Expect division
/// quotient of two rational values
/// panics if the second value is 0 (expect)
/// ```aiken
/// expect_new(x, y) |> expect_div(expect_new(a, b)) == new(x*b, y*a)
/// ```
pub fn expect_div(a: Rational, b: Rational) -> Rational {
  expect_recip(b) |> mul(a)
}

test div_1() {
  ( expect_new(2, 3) |> expect_div(expect_new(3, 4)) ) == Rational {
    numerator: 8,
    denominator: 9,
  }
}

test div_2() {
  ( expect_new(2, 3) |> expect_div(expect_new(-3, 4)) ) == Rational {
    numerator: -8,
    denominator: 9,
  }
}

/// Ratio of integers, a rational
/// none if the second value is 0
/// ```aiken
/// new(x, 0) == None
/// new(x, y) == Some(expect_new(x, y))
/// ```
pub fn new(numerator: Int, denominator: Int) -> Option<Rational> {
  if denominator == 0 {
    None
  } else if denominator < 0 {
    Some(Rational { numerator: -numerator, denominator: -denominator })
  } else {
    Some(Rational { numerator, denominator })
  }
}

test new_zero() {
  new(2, 0) == None
}

test new_1() {
  new(2, 3) == Some(Rational { numerator: 2, denominator: 3 })
}

test new_2() {
  new(-2, 3) == Some(Rational { numerator: -2, denominator: 3 })
}

test new_3() {
  new(2, -3) == Some(Rational { numerator: -2, denominator: 3 })
}

test new_4() {
  new(2, 4) == Some(Rational { numerator: 2, denominator: 4 })
}

test new_5() {
  new(-2, -3) == Some(Rational { numerator: 2, denominator: 3 })
}

test new_6() {
  new(-2, -4) == Some(Rational { numerator: 2, denominator: 4 })
}

/// Create a new Rational
/// quotient of two integers
/// panics if the second value is 0 (expect)
/// ```aiken
/// Some(expect_new(x, y)) == new(x, y)
/// expect_new(x, 0) == error
/// ```
pub fn expect_new(numerator: Int, denominator: Int) -> Rational {
  if denominator == 0 {
    error @"Division by 0"
  } else if denominator < 0 {
    Rational { numerator: -numerator, denominator: -denominator }
  } else {
    Rational { numerator, denominator }
  }
}

test expect_new_1() {
  expect_new(2, 3) == Rational { numerator: 2, denominator: 3 }
}

test expect_new_2() {
  expect_new(-2, 3) == Rational { numerator: -2, denominator: 3 }
}

test expect_new_3() {
  expect_new(2, -3) == Rational { numerator: -2, denominator: 3 }
}

test expect_new_4() {
  expect_new(2, 4) == Rational { numerator: 2, denominator: 4 }
}

test expect_new_5() {
  expect_new(-2, -3) == Rational { numerator: 2, denominator: 3 }
}

test expect_new_6() {
  expect_new(-2, -4) == Rational { numerator: 2, denominator: 4 }
}

/// Addition
/// sum of two rational values
/// ```aiken
/// add(new(x, y), new(a, b)) == new(x*b + a*y, y*b)
/// ```
pub fn add(a: Rational, b: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  Rational { numerator: a_n * b_d + b_n * a_d, denominator: a_d * b_d }
}

test add_1() {
  ( expect_new(2, 3) |> add(expect_new(3, 4)) ) == Rational {
    numerator: 17,
    denominator: 12,
  }
}

/// Subtraction
/// difference of two rational values
/// ```aiken
/// expect_new(x, y) |> sub(expect_new(a, b)) == new(x*b - a*y, y*b)
/// ```
pub fn sub(a: Rational, b: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  Rational { numerator: a_n * b_d - b_n * a_d, denominator: a_d * b_d }
}

test sub_1() {
  ( expect_new(2, 3) |> sub(expect_new(3, 4)) ) == Rational {
    numerator: -1,
    denominator: 12,
  }
}

/// Greater than
/// ```aiken
/// gt(new(5, 7), new(5, 6)) == False
/// gt(new(5, 6), new(5, 7)) == True
/// ```
pub fn gt(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d > b_n * a_d
}

test gt_1() {
  expect_new(2, 3) |> gt(expect_new(1, 3))
}

test gt_2() {
  ( expect_new(2, 3) |> gt(expect_new(2, 3)) ) == False
}

/// Less than
/// ```aiken
/// lt(expect_new(5, 7), expect_new(5, 6)) == True
/// lt(expect_new(5, 6), expect_new(5, 7)) == False
/// ```
pub fn lt(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d < b_n * a_d
}

test lt_1() {
  expect_new(2, 3) |> lt(expect_new(3, 4))
}

test lt_2() {
  ( expect_new(2, 3) |> lt(expect_new(2, 3)) ) == False
}

/// Greater than or equal
/// ```aiken
/// ge(expect_new(5, 7), expect_new(5, 6)) == False
/// ge(expect_new(5, 6), expect_new(5, 7)) == True
/// ge(expect_new(5, 6), expect_new(5, 6)) == True
/// ```
pub fn ge(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d >= b_n * a_d
}

test ge_1() {
  expect_new(2, 3) |> ge(expect_new(1, 3))
}

test ge_2() {
  expect_new(2, 3) |> ge(expect_new(2, 3))
}

/// Less than or equal
/// ```aiken
/// le(expect_new(5, 7), expect_new(5, 6)) == True
/// le(expect_new(5, 6), expect_new(5, 7)) == False
/// le(expect_new(5, 6), expect_new(5, 6)) == True
/// ```
pub fn le(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d <= b_n * a_d
}

test le_1() {
  expect_new(2, 3) |> le(expect_new(3, 4))
}

test le_2() {
  expect_new(2, 3) |> le(expect_new(2, 3))
}

/// Equal
/// ```aiken
/// eq(expect_new(5, 7), expect_new(5, 6)) == False
/// eq(expect_new(5, 6), expect_new(5, 7)) == False
/// eq(expect_new(5, 6), expect_new(5, 6)) == True
/// ```
pub fn eq(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d == b_n * a_d
}

test eq_1() {
  expect_new(2, 3) |> eq(expect_new(2, 3))
}

/// Not Equal
/// ```aiken
/// neq(Rational expect_new(5, 7), expect_new(5, 6)}) == True
/// neq(Rational (5, 6), expect_new(5, 7)) == True
/// expect_new(5, 6) |> neq(expect_new(5, 7)) == True
/// ```
pub fn neq(a: Rational, b: Rational) -> Bool {
  let Rational { numerator: a_n, denominator: a_d } = a
  let Rational { numerator: b_n, denominator: b_d } = b
  a_n * b_d != b_n * a_d
}

test neq_1() {
  expect_new(2, 3) |> neq(expect_new(1, 3))
}

/// Create a new Rational from an Int
/// ```aiken
/// from_int(-5) == expect_new(-5, 1)
/// from_int(3) == expect_new(3, 1)
/// from_int(0) == expect_new(0, 1)
/// ```
pub fn from_int(a: Int) -> Rational {
  Rational { numerator: a, denominator: 1 }
}

test from_int_1() {
  from_int(3) == expect_new(3, 1)
}

/// Truncate a Rational to convert it to an Int
/// ```aiken
/// truncate(expect_new(5, 2)) == 2
/// truncate(expect_new(5, 3)) == 1
/// truncate(expect_new(5, 4)) == 1
/// truncate(expect_new(5, 5)) == 1
/// truncate(expect_new(5, 6)) == 0
/// ```
pub fn truncate(a: Rational) -> Int {
  let Rational { numerator: a_n, denominator: a_d } = a
  a_n / a_d
}

test truncate_1() {
  ( expect_new(8, 3) |> truncate ) == 2
}

/// Rounds the argument up towards positive infinity.
pub fn ceiling(x: Rational) -> Int {
  let Rational { numerator, denominator } = x
  if numerator % denominator == 0 {
    numerator / denominator
  } else {
    numerator / denominator + 1
  }
}

test ceiling_test1() {
  ceiling(expect_new(13, 5)) == 3
}

test ceiling_test2() {
  ceiling(expect_new(15, 5)) == 3
}

test ceiling_test3() {
  ceiling(expect_new(16, 5)) == 4
}

test ceiling_test4() {
  ceiling(expect_new(-3, 5)) == 0
}

test ceiling_test5() {
  ceiling(expect_new(-5, 5)) == -1
}

test ceiling_test6() {
  ceiling(expect_new(-6, 5)) == -1
}

/// Return the proper fraction of the argument.
pub fn proper_fraction(x: Rational) -> (Int, Rational) {
  let Rational { numerator, denominator } = x
  (
    numerator / denominator,
    Rational { numerator: numerator % denominator, denominator },
  )
}

test proper_fraction_test1() {
  proper_fraction(expect_new(10, 7)) == (
    1,
    Rational { numerator: 3, denominator: 7 },
  )
}

test proper_fraction_test2() {
  proper_fraction(expect_new(-10, 7)) == (
    -2,
    Rational { numerator: 4, denominator: 7 },
  )
}

/// Round the argument to the nearest whole number. If the argument is equidistant between two
/// values, the greater value is returned.
pub fn round(x: Rational) -> Int {
  let (n, r) = proper_fraction(x)
  let m =
    if lt(r, from_int(0)) {
      n - 1
    } else {
      n + 1
    }
  let flag = sub(abs(r), expect_new(1, 2))
  if lt(flag, from_int(0)) {
    n
  } else {
    m
  }
}

test round_test1() {
  round(expect_new(-10, 7)) == -1
}

test round_test2() {
  round(expect_new(10, 7)) == 1
}

test round_test3() {
  round(expect_new(11, 7)) == 2
}

test round_test4() {
  round(expect_new(3, 2)) == 2
}

test round_test5() {
  round(expect_new(5, 2)) == 3
}

/// Change the sign of a Rational
/// ```aiken
/// neg(expect_new(5, 2)) == expect_new(-5, 2)
/// neg(expect_new(-5, 2)) == expect_new(5, 2)
/// neg(neg(x)) == x
/// ```
pub fn neg(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  Rational { numerator: -a_n, denominator: a_d }
}

test neg_1() {
  ( expect_new(2, 3) |> neg ) == Rational { numerator: -2, denominator: 3 }
}

/// Absolute value of a Rational
/// ```aiken
/// abs(expect_new(5, 2)) == expect_new(5, 2)
/// abs(expect_new(-5, 2)) == expect_new(5, 2)
/// abs(expect_new(x, y)) == abs(expect_new(-x, y))
/// ```
pub fn abs(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  Rational { numerator: math.abs(a_n), denominator: a_d }
}

test abs_1() {
  ( expect_new(-2, 3) |> abs ) == Rational { numerator: 2, denominator: 3 }
}

/// Reciprocal of a Rational
/// ```aiken
/// expect_new(5, 2) |> recip() == new(2, 5)
/// expect_new(-5, 2) |> recip() == new(-2, 5)
/// expect_new(0, 2) |> recip() == None
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
  ( new(2, 3) |> option.map(recip) ) == Some(new(3, 2))
}

test recip_2() {
  ( new(-2, 3) |> option.map(recip) ) == Some(new(-3, 2))
}

/// Reciprocal of a Rational
/// Expects the numerator to be non-zero
/// ```aiken
/// expect_new(5, 2) |> expect_recip() == expect_new(2, 5)
/// expect_new(-6, 7) |> expect_recip() == expect_new(-7, 6)
/// expect_new(0, 2) |> expect_recip() == error
/// ```
pub fn expect_recip(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  if a_n < 0 {
    Rational { numerator: -a_d, denominator: -a_n }
  } else if a_n > 0 {
    Rational { numerator: a_d, denominator: a_n }
  } else {
    error @"Denominator cannot be 0"
  }
}

test expect_recip_1() {
  ( new(2, 3) |> option.map(expect_recip) ) == Some(
    Rational { numerator: 3, denominator: 2 },
  )
}

test expect_recip_2() {
  ( new(-2, 3) |> option.map(expect_recip) ) == Some(
    Rational { numerator: -3, denominator: 2 },
  )
}

/// Reduce a rational to its irreducible form
/// Making the numerator and denominator coprime
/// ```aiken
/// new(80, 200) |> option.map(reduce) == new(2, 5)
/// div_(-5, 1) |> option.map(reduce) == new(-5, 1)
/// ```
pub fn reduce(a: Rational) -> Rational {
  let Rational { numerator: a_n, denominator: a_d } = a
  let d = math.gcd(a_n, a_d)
  Rational { numerator: a_n / d, denominator: a_d / d }
}

test reduce_1() {
  ( new(5040, 18018) |> option.map(reduce) ) == Some(
    Rational { numerator: 40, denominator: 143 },
  )
}

test reduce_2() {
  ( new(-20, 4) |> option.map(reduce) ) == Some(
    Rational { numerator: -5, denominator: 1 },
  )
}

/// Compare two rationals for an ordering
/// ```aiken
/// new(5, 2) |> option.map(compare(_, expect_new(5, 2))) == Some(Equal)
/// new(5, 2) |> option.map(compare(_, expect_new(10, 4))) == Some(Equal)
/// compare(expect_new(5, 2), expect_new(5, 3)) == Greater
/// expect_new(5, 2) |> compare(expect_new(5, 1)) == Less
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
  ( new(3, 8) |> option.map(compare(_, expect_new(-2, 4))) ) == Some(Greater)
}

test compare_2() {
  ( expect_new(3, 8) |> compare(expect_new(2, 4)) ) == Less
}

test compare_3() {
  ( expect_new(3, 8) |> compare(expect_new(3, 8)) ) == Equal
}

/// The `Rational` for zero.
pub fn zero() -> Rational {
  0 |> from_int
}

test zero_1() {
  zero() == Rational { numerator: 0, denominator: 1 }
}
