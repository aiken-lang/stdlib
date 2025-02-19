use aiken/builtin
use aiken/math/bitwise.{add}

test one_plus_one() {
  let one = builtin.integer_to_bytearray(True, 0, 1)
  let two = builtin.integer_to_bytearray(True, 0, 2)
  add(one, one) == two
}

test emptiness_is_empty() {
  add(#"", #"") == #""
}

test not_equal_length_does_not_work() fail {
  add(#"00", #"acab") == #"acab"
}

test communitive() {
  add(#"acab", #"0000") == add(#"0000", #"acab")
}

test associativity() {
  ( add(#"0101", #"0202") |> add(#"0303") ) == (
    add(#"0202", #"0303") |> add(#"0101")
  )
}

test identity() {
  add(#"00", #"01") == #"01"
}
