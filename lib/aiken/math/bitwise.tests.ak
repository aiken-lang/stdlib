use aiken/math/bitwise.{
  add, multiply, pad_for_addition, pad_for_multiply, subtract,
}

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

test equal_pad_for_multiply() {
  let a: ByteArray = #"acab"
  let b: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_multiply(a, b)
  and {
    new_a == #"0000acab",
    new_b == #"0000cafe",
  }
}

test unequal_pad_for_multiply1() {
  let a: ByteArray = #"acabbeefface"
  let b: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_multiply(a, b)
  and {
    new_a == #"000000000000acabbeefface",
    new_b == #"00000000000000000000cafe",
  }
}

test unequal_pad_for_multiply2() {
  let b: ByteArray = #"acabbeefface"
  let a: ByteArray = #"cafe"
  let (new_a, new_b) = pad_for_multiply(a, b)
  and {
    new_a == #"00000000000000000000cafe",
    new_b == #"000000000000acabbeefface",
  }
}

test simple_multiply1() {
  multiply(#"0000ffff", #"0000ffff") == #"fffe0001"
}

test multiply_communitive() {
  multiply(#"0000acab", #"0000cafe") == multiply(#"0000cafe", #"0000acab")
}
