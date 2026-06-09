use aiken/array

test from_list_length() {
  let xs = array.from_list([11, 22, 33])
  array.length(xs) == 3
}

test at_in_bounds() {
  let xs = array.from_list([11, 22, 33])
  array.at(xs, 1) == Some(22)
}

test at_out_of_bounds_hi() {
  let xs = array.from_list([11, 22, 33])
  array.at(xs, 3) == None
}

test at_out_of_bounds_lo() {
  let xs = array.from_list([11, 22, 33])
  array.at(xs, -1) == None
}
