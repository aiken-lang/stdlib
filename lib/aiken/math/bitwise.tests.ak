use aiken/math/bitwise.{add, pad_for_addition, subtract}

test equal_pad_for_addition() {
  let a: ByteArray = #"acab"
  let b: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_addition(a, b)
  and {
    new_a == #"00acab",
    new_b == #"00cafe",
  }
}

test unequal_pad_for_addition1() {
  let a: ByteArray = #"acabbeefface"
  let b: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_addition(a, b)
  and {
    new_a == #"00acabbeefface",
    new_b == #"0000000000cafe",
  }
}

test unequal_pad_for_addition2() {
  let b: ByteArray = #"acabbeefface"
  let a: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_addition(a, b)
  and {
    new_a == #"0000000000cafe",
    new_b == #"00acabbeefface",
  }
}

test pad_for_addition_does_works() {
  let b: ByteArray = #"acab"
  let a: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_addition(a, b)
  and {
    add(a, b) == #"77a9",
    add(new_a, new_b) == #"0177a9",
  }
}

test emptiness_is_empty() {
  add(#"", #"") == #""
}

test adding_not_equal_length_does_not_work() fail {
  add(#"00", #"acab") == #"acab"
}

test add_communitive() {
  add(#"acab", #"cafe") == add(#"cafe", #"acab")
}

test add_associativity() {
  ( add(#"0101", #"0202") |> add(#"0303") ) == (
    add(#"0202", #"0303") |> add(#"0101")
  )
}

test add_identity() {
  add(#"00", #"01") == #"01"
}

test subtracting_does_work1() {
  subtract(#"0177a9", #"00cafe") == #"00acab"
}

test subtracting_does_work2() {
  subtract(#"77a9", #"cafe") == #"acab"
}

test subtracting_not_equal_length_does_not_work() fail {
  subtract(#"0177a9", #"cafe") == #"acab"
}

test subtract_is_not_communitive() fail {
  subtract(#"acab", #"cafe") == add(#"cafe", #"acab")
}

test subtract_identity() {
  subtract(#"10", #"00") == #"10"
}
