use aiken/math/rational.{Rational, int_power, new}
use aiken/fuzz.{both, either, map}

fn positive_rational_fuzz() -> Fuzzer<Rational>{
  map(
    both(fuzz.int_at_least(1), fuzz.int_at_least(1)), 
    fn((num,den)){
      expect Some(new_fraction) = new(num,den)
      new_fraction
    }
  )
}

fn negative_rational_fuzz() -> Fuzzer<Rational>{
  map(both(fuzz.int_at_most(-1),fuzz.int_at_least(1)),
    fn((num,den)){
      expect Some(new_fraction) = new(num,den)
      new_fraction
    }
  )
}

fn rational_fuzz() -> Fuzzer<Rational> {
  either(negative_rational_fuzz(),positive_rational_fuzz())
}

test prop_power_of_zero_returns_one(rational via rational_fuzz()){
  expect Some(calculated_result) = int_power(rational, 0)
  expect Some(expected_result) = new(1,1)
  calculated_result == expected_result
}

test prop_power_of_one_returns_same_fraction(rational via rational_fuzz()){
  expect Some(calculated_result) = int_power(rational, 1)
  calculated_result == rational
}

test prop_power_numerator_zero_exponent_negative_returns_none((denominator,exponent) via both(fuzz.int_at_least(1),fuzz.int_at_most(-1))){
  expect Some(fraction) = new(0, denominator)
  expect None = int_power(fraction,exponent)
}


test prop_power_unit_fraction_is_immutable(exponent via fuzz.int()) {
  expect Some(unit) = new(1,1)
  expect Some(calculated_result) = int_power(unit, exponent)
  calculated_result == unit
}