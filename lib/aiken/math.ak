//// This module contains some basic Math utilities. Standard arithmetic
//// operations on integers are available through native operators:
////
//// operator | Description
//// ---      | ---
//// +        | Arithmetic sum
//// -        | Arithmetic difference
//// /        | Whole division
//// *        | Arithmetic multiplication
//// %        | Remainder by whole division
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
/// use aiken/math
///
/// math.abs(-42)
/// // 42
///
/// math.abs(14)
/// // 14
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
/// use aiken/math
///
/// math.clamp(14, min: 0, max: 10)
/// // 10
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

/// Calculates x to the power of n using the exponentiation by squaring method.
/// This power function is designed for Plutus.
///
/// ```aiken
/// use aiken/math
///
/// math.pow(513, 3)
/// // 135005697
/// ```
pub fn pow(x: Int, n: Int) -> Int {
  if n < 0 {
    0
  } else if n == 0 {
    1
  } else if n % 2 == 0 {
    pow(x * x, n / 2)
  } else {
    x * pow(x * x, ( n - 1 ) / 2)
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

/// Calculates the x to the power of n modulo q.
///
/// ```aiken
/// use aiken/math
///
/// math.powmod(1425, 2434, 71)
/// // 57
/// ```
pub fn powmod(x: Int, n: Int, q: Int) -> Int {
  if q <= 0 {
    0
  } else {
    pow(x, n) % q
  }
}

test powmod_131_4_3() {
  powmod(131, 4, 3) == 1
}

test powmod_13_34_0() {
  powmod(13, 34, 0) == 0
}

test powmod_1425_2434_71() {
  powmod(1425, 2434, 71) == 57
}

/// The log of x in base b for plutus. This is the integer division version.
///
/// ```aiken
/// use aiken/math
///
/// log_x_in_base_b(42, 3)
/// // 3
/// ```
pub fn log_x_in_base_b(x: Int, b: Int) -> Int {
  if b <= 0 {
    0
  } else if x == b {
    1
  } else if x < b {
    0
  } else {
    1 + log_x_in_base_b(x / b, b)
  }
}

test log_5_0() {
  log_x_in_base_b(5, 0) == 0
}

test log_4_4() {
  log_x_in_base_b(4, 4) == 1
}

test log_4_43() {
  log_x_in_base_b(4, 43) == 0
}

test log_42_3() {
  log_x_in_base_b(42, 3) == 3
}
