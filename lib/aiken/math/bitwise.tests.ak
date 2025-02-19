use aiken/math/bitwise.{add, pad_addition}

test equal_pad_addition() {
  let a: ByteArray = #"acab"
  let b: ByteArray = #"cafe"
  let (new_a, new_b) = pad_addition(a, b)
  and {
    new_a == #"00acab",
    new_b == #"00cafe",
  }
}

test unequal_pad_addition1() {
  let a: ByteArray = #"acabbeefface"
  let b: ByteArray = #"cafe"
  let (new_a, new_b) = pad_addition(a, b)
  and {
    new_a == #"00acabbeefface",
    new_b == #"0000000000cafe",
  }
}

test unequal_pad_addition2() {
  let b: ByteArray = #"acabbeefface"
  let a: ByteArray = #"cafe"
  let (new_a, new_b) = pad_addition(a, b)
  and {
    new_a == #"0000000000cafe",
    new_b == #"00acabbeefface",
  }
}

test pad_for_addition() {
  let b: ByteArray = #"acab"
  let a: ByteArray = #"cafe"
  let (new_a, new_b) = pad_addition(a, b)
  and {
    add(a, b) == #"77a9",
    add(new_a, new_b) == #"0177a9",
  }
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
