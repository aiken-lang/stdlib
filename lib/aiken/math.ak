//// This module contains some basic Math utilities. Standard arithmetic
//// operations on integers are available through native operators:
////
//// Operator | Description
//// ---      | :---
//// `+`      | Arithmetic sum
//// `-`      | Arithmetic difference
//// `/`      | Whole division
//// `*`      | Arithmetic multiplication
//// `%`      | Remainder by whole division
////
//// Here are a few examples:
////
//// ```aiken
//// 1 + 1   // 2
//// 10 - 2  // 8
//// 40 / 14 // 2
//// 3 * 4   // 12
//// 10 % 3  // 1

/// Calculate the absolute value of an integer.
///
/// ```aiken
/// math.abs(-42) == 42
/// math.abs(14) == 14
/// ```
pub fn abs(self: Int) -> Int {
  if self < 0 {
    0 - self
  } else {
    self
  }
}

test abs_1() {
  abs(14) == 14
}

test abs_2() {
  abs(-42) == 42
}

/// Restrict the value of an integer between two min and max bounds
///
/// ```aiken
/// math.clamp(14, min: 0, max: 10) == 10
/// ```
pub fn clamp(self: Int, min: Int, max: Int) -> Int {
  if self < min {
    min
  } else {
    if self > max {
      max
    } else {
      self
    }
  }
}

test clamp_1() {
  clamp(14, min: 0, max: 10) == 10
}

test clamp_2() {
  clamp(7, min: 0, max: 10) == 7
}

test clamp_3() {
  clamp(7, min: 10, max: 100) == 10
}

/// Return the maximum of two integers.
pub fn max(a: Int, b: Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

test max_1() {
  max(0, 0) == 0
}

test max_2() {
  max(14, 42) == 42
}

test max_3() {
  max(42, 14) == 42
}

/// Return the minimum of two integers.
pub fn min(a: Int, b: Int) -> Int {
  if a > b {
    b
  } else {
    a
  }
}

test min_1() {
  min(0, 0) == 0
}

test min_2() {
  min(14, 42) == 14
}

test min_3() {
  min(42, 14) == 14
}

/// Calculates a number to the power of `e` modulo q using the exponentiation by
/// squaring method modulo q.
///
/// ```aiken
/// math.powmod(3, 5, 3) == 0
/// math.powmod(7, 2, 3) == 1
/// math.powmod(3, -4, 5) == 0
/// math.powmod(0, 0, 0) == 1
/// math.powmod(513, 3, 35) == 22
/// ```
pub fn powmod(self: Int, e: Int, q: Int) -> Int {
  if e < 0 {
    0
  } else if e == 0 {
    1
  } else if e % 2 == 0 {
    powmod(self * self % q, e / 2, q)
  } else {
    self * powmod(self * self % q, ( e - 1 ) / 2, q) % q
  }
}

test simple_powmod_test() {
  powmod(2, 4, 2) == 0
}

test md_pow_speed_compare() {
  pow(2, 12345) % 1561 == 1149
}

test md_size_powmod() {
  powmod(2, 12345, 1561) == 1149
}

test lg_size_powmod() {
  powmod(2, 1234567890, 999931) == 497611
}

// // this takes forever
// test lg_powmod_compare() {
//   pow(2, 1234567890) % 999931 == 497611
// }

test xl_size_powmod() {
  powmod(2, 12345678901234567890, 9999991) == 7037275
}

test xxl_size_powmod() {
  powmod(2, 1234567890123456789012345678901234567890, 999999929) == 744999773
}

test dammmnn_size_powmod() {
  powmod(
    2,
    12345678901234567890123456789012345678901234567890123456789012345678901234567890,
    9223372036854775783,
  ) == 8238788744143562492
}

/// Calculates a number to the power of `e` using the exponentiation by
/// squaring method.
///
/// ```aiken
/// math.pow(3, 5) == 243
/// math.pow(7, 2) == 49
/// math.pow(3, -4) == 0
/// math.pow(0, 0) == 1
/// math.pow(513, 3) == 135005697
/// ```
pub fn pow(self: Int, e: Int) -> Int {
  if e < 0 {
    0
  } else if e == 0 {
    1
  } else if e % 2 == 0 {
    pow(self * self, e / 2)
  } else {
    self * pow(self * self, ( e - 1 ) / 2)
  }
}

test pow_3_5() {
  pow(3, 5) == 243
}

test pow_7_2() {
  pow(7, 2) == 49
}

test pow_3__4() {
  // negative powers round to zero
  pow(3, -4) == 0
}

test pow_0_0() {
  // sorry math
  pow(0, 0) == 1
}

test pow_513_3() {
  pow(513, 3) == 135005697
}

/// The logarithm in base `b` of an element using integer divisions.
///
/// ```aiken
/// math.log(10, base: 2) == 3
/// math.log(42, base: 2) == 5
/// math.log(42, base: 3) == 3
/// math.log(5, base: 0) == 0
/// math.log(4, base: 4) == 1
/// math.log(4, base: 42) == 0
/// ```
pub fn log(self: Int, base: Int) -> Int {
  if base <= 0 {
    0
  } else if self == base {
    1
  } else if self < base {
    0
  } else {
    1 + log(self / base, base)
  }
}

test log_10_2() {
  log(10, base: 2) == 3
}

test log_42_2() {
  log(42, base: 2) == 5
}

test log_42_3() {
  log(42, base: 3) == 3
}

test log_5_0() {
  log(5, base: 0) == 0
}

test log_4_4() {
  log(4, base: 4) == 1
}

test log_4_43() {
  log(4, base: 43) == 0
}
