use aiken/array

test from_list_length() {
  let xs = array.from_list([11, 22, 33])
  array.length(xs) == 3
}

test is_empty_1() {
  array.from_list([]) |> array.is_empty
}

test is_empty_2() {
  let xs = array.from_list([11])
  array.is_empty(xs) == False
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

test foldl_sum() {
  let xs = array.from_list([1, 2, 3, 4])
  array.foldl(xs, 0, fn(item, total) { item + total }) == 10
}

test foldr_to_list() {
  let xs = array.from_list([1, 2, 3, 4])
  array.foldr(xs, [], fn(item, items) { [item, ..items] }) == [1, 2, 3, 4]
}

test to_list_preserves_order() {
  let xs = array.from_list([1, 2, 3, 4])
  array.to_list(xs) == [1, 2, 3, 4]
}

test map_preserves_order() {
  let xs = array.from_list([1, 2, 3, 4])
  let ys = xs |> array.map(fn(item) { item * 2 })
  array.to_list(ys) == [2, 4, 6, 8]
}

test all_1() {
  let xs = array.from_list([1, 2, 3])
  array.all(xs, fn(item) { item > 0 })
}

test all_2() {
  let xs = array.from_list([1, 2, 3])
  array.all(xs, fn(item) { item > 2 }) == False
}

test any_1() {
  let xs = array.from_list([1, 2, 3])
  array.any(xs, fn(item) { item == 2 })
}

test any_2() {
  let xs = array.from_list([1, 2, 3])
  array.any(xs, fn(item) { item > 5 }) == False
}
