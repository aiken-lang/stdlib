use aiken/builtin

/// Add an element in front of the list. Sometimes useful when combined with
/// other functions.
///
/// ```aiken
/// use aiken/list
///
/// list.add_front([2, 3], 1) == [1, ..[2, 3]] == [1, 2, 3]
/// ```
pub fn add_front(xs: List<a>, x: a) -> List<a> {
  [x, ..xs]
}

test add_front_1() {
  add_front([], 0) == [0]
}

test add_front_2() {
  add_front([2, 3], 1) == [1, 2, 3]
}

/// Determine if all elements of the list satisfy the given predicate.
///
/// Note: an empty list always satisfies the predicate.
pub fn all(xs: List<a>, predicate: fn(a) -> Bool) -> Bool {
  when xs is {
    [] -> True
    [x, ..rest] -> predicate(x) && all(rest, predicate)
  }
}

test all_1() {
  all([1, 2, 3], fn(n) { n > 0 }) == True
}

test all_2() {
  all([1, 2, 3], fn(n) { n > 42 }) == False
}

test all_3() {
  all([], fn(n) { n == 42 }) == True
}

/// Determine if at least one element of the list satisfies the given predicate.
///
/// Note: an empty list always satisfies the predicate.
pub fn any(xs: List<a>, predicate: fn(a) -> Bool) -> Bool {
  when xs is {
    [] -> False
    [x, ..rest] -> predicate(x) || any(rest, predicate)
  }
}

test any_1() {
  any([1, 2, 3], fn(n) { n > 0 }) == True
}

test any_2() {
  any([1, 2, 3], fn(n) { n > 42 }) == False
}

test any_3() {
  any([], fn(n) { n == 42 }) == False
}

/// Merge two lists together.
pub fn concat(left: List<a>, right: List<a>) -> List<a> {
  foldr(left, fn(x, xs) { [x, ..xs] }, right)
}

test concat_1() {
  concat([1, 2, 3], [4, 5, 6]) == [1, 2, 3, 4, 5, 6]
}

test concat_2() {
  concat([1, 2, 3], []) == [1, 2, 3]
}

test concat_3() {
  concat([], [1, 2, 3]) == [1, 2, 3]
}

/// Drop the first `n` elements of a list.
pub fn drop(xs: List<a>, n: Int) -> List<a> {
  if n <= 0 {
    xs
  } else {
    when xs is {
    [] -> []
    [_x, ..rest] -> drop(rest, n - 1)
  }
  }
}

test drop_1() {
  drop([], 42) == []
}

test drop_2() {
  drop([1, 2, 3], 2) == [3]
}

/// Produce a list from elements that statisfy a predicate.
pub fn filter(xs: List<a>, f: fn(a) -> Bool) -> List<a> {
  when xs is {
    [] -> []
    [x, ..rest] ->
      if f(x) {
        [x, ..filter(rest, f)]
      } else {
        filter(rest, f)
      }
  }
}

test filter_1() {
  filter([], fn(x) { x > 0 }) == []
}

test filter_2() {
  let xs = [1, 2, 3, 4, 5, 6]
  filter(xs, fn(x) { builtin.mod_integer(x, 2) == 0 }) == [2, 4, 6]
}

test filter_3() {
  let filter_foldr = fn(xs, f) {
    foldr(
      xs,
      fn(x, ys) {
        if f(x) {
          [x, ..ys]
        } else {
          ys
        }
      },
      [],
    )
  }

  let is_odd = fn(n) { builtin.mod_integer(n, 2) != 0 }

  filter_foldr([1, 2, 3], is_odd) == filter([1, 2, 3], is_odd)
}

/// Produce a list from elements that statisfy a predicate.
pub fn filter_map(xs: List<a>, f: fn(a) -> Option<b>) -> List<b> {
  when xs is {
    [] -> []
    [x, ..rest] ->
      when f(x) is {
        None -> filter_map(rest, f)
        Some(y) -> [y, ..filter_map(rest, f)]
      }
  }
}

test filter_map_1() {
  filter_map([], fn(_) { Some(42) }) == []
}

test filter_map_2() {
  filter_map(
    [1, 2, 3, 4, 5, 6],
    fn(x) {
      if builtin.mod_integer(x, 2) != 0 {
        Some(3 * x)
      } else {
        None
      }
    },
  ) == [3, 9, 15]
}

/// Find the first element satisfying the given predicate, if any.
pub fn find(xs: List<a>, f: fn(a) -> Bool) -> Option<a> {
  when xs is {
    [] -> None
    [x, ..rest] ->
      if f(x) {
        Some(x)
      } else {
        find(rest, f)
      }
  }
}

test find_1() {
  find([1, 2, 3], fn(x) { x == 1 }) == Some(1)
}

test find_2() {
  find([1, 2, 3], fn(x) { x > 42 }) == None
}

test find_3() {
  find([], fn(_) { True }) == None
}

/// Map elements of a list into a new list and flatten the result.
pub fn flat_map(xs: List<a>, f: fn(a) -> List<b>) -> List<b> {
  foldr(xs, fn(x, ys) { concat(f(x), ys) }, [])
}

test flat_map_1() {
  flat_map([], fn(a) { [a] }) == []
}

test flat_map_2() {
  flat_map([1, 2, 3], fn(a) { [a, a] }) == [1, 1, 2, 2, 3, 3]
}

/// Reduce a list from left to right.
pub fn foldl(xs: List<a>, f: fn(a, b) -> b, zero: b) -> b {
  when xs is {
    [] -> zero
    [x, ..rest] -> foldl(rest, f, f(x, zero))
  }
}

test foldl_1() {
  foldl([], fn(_, _) { 1 }, 0) == 0
}

test foldl_2() {
  foldl([1, 2, 3, 4, 5], fn(n, total) { n + total }, 0) == 15
}

test foldl_3() {
  foldl([1, 2, 3, 4], fn(x, xs) { [x, ..xs] }, []) == [4, 3, 2, 1]
}

/// Reduce a list from right to left.
pub fn foldr(xs: List<a>, f: fn(a, b) -> b, zero: b) -> b {
  when xs is {
    [] -> zero
    [x, ..rest] -> f(x, foldr(rest, f, zero))
  }
}

test foldr_1() {
  foldr([1, 2, 3, 4, 5], fn(n, total) { n + total }, 0) == 15
}

test foldr_2() {
  foldr(
    [1, 2, 3],
    fn(n, _str) {
      if builtin.mod_integer(n, 2) == 0 {
        "foo"
      } else {
        "bar"
      }
    },
    "",
  ) == "bar"
}

test foldr_3() {
  foldr([1, 2, 3, 4], fn(x, xs) { [x, ..xs] }, []) == [1, 2, 3, 4]
}

/// Get the first element of a list
pub fn head(xs: List<a>) -> Option<a> {
  when xs is {
    [] -> None
    _ -> Some(builtin.head_list(xs))
  }
}

test head_1() {
  head([1, 2, 3]) == Some(1)
}

test head_2() {
  head([]) == None
}

pub fn indexed_foldr(
  xs: List<a>,
  f: fn(Int, a, result) -> result,
  zero: result,
) -> result {
  do_indexed_foldr(0, xs, f, zero)
}

fn do_indexed_foldr(
  n: Int,
  xs: List<a>,
  f: fn(Int, a, result) -> result,
  zero: result,
) -> result {
  when xs is {
    [] -> zero
    [x, ..rest] -> f(n, x, do_indexed_foldr(n + 1, rest, f, zero))
  }
}

test indexed_foldr_1() {
  indexed_foldr([], fn(i, x, xs) { i + x + xs }, 0) == 0
}

test indexed_foldr_2() {
  let letters = ["a", "b", "c"]
  indexed_foldr(letters, fn(i, x, xs) { [#(i, x), ..xs] }, []) == [
    #(0, "a"),
    #(1, "b"),
    #(2, "c"),
  ]
}

/// Apply a function to each element of a list.
pub fn indexed_map(xs: List<a>, f: fn(Int, a) -> result) -> List<result> {
  do_indexed_map(0, xs, f)
}

fn do_indexed_map(n: Int, xs: List<a>, f: fn(Int, a) -> result) -> List<result> {
  when xs is {
    [] -> []
    [x, ..rest] -> [f(n, x), ..do_indexed_map(n + 1, rest, f)]
  }
}

test indexed_map_1() {
  indexed_map([], fn(i, _n) { i }) == []
}

test indexed_map_2() {
  indexed_map(
    [4, 8, 13, 2],
    fn(i, n) {
      if n == 8 {
        n
      } else {
        i
      }
    },
  ) == [0, 8, 2, 3]
}

/// Figures out whether a list contain the given element.
pub fn is_elem(xs: List<a>, x: a) -> Bool {
  when xs is {
    [] -> False
    [y, ..rest] ->
      if x == y {
        True
      } else {
        is_elem(rest, x)
      }
  }
}

test is_elem_1() {
  is_elem([1, 2, 3], 1) == True
}

test is_elem_2() {
  is_elem([1, 2, 3], 14) == False
}

test is_elem_3() {
  is_elem([], 14) == False
}

/// Get the number of elements in the given list.
pub fn length(xs: List<a>) -> Int {
  when xs is {
    [] -> 0
    [_, ..rest] -> 1 + length(rest)
  }
}

test length_1() {
  length([]) == 0
}

test length_2() {
  length([1, 2, 3]) == 3
}

/// Apply a function to each element of a list.
pub fn map(xs: List<a>, f: fn(a) -> result) -> List<result> {
  when xs is {
    [] -> []
    [x, ..rest] -> [f(x), ..map(rest, f)]
  }
}

test map_1() {
  map([], fn(n) { n + 1 }) == []
}

test map_2() {
  map([1, 2, 3, 4], fn(n) { n + 1 }) == [2, 3, 4, 5]
}

/// Apply a function of two arguments, combining elements from two lists.
///
/// Note: if one list is longer, the extra elements are dropped.
pub fn map2(xs: List<a>, ys: List<b>, f: fn(a, b) -> result) -> List<result> {
  when xs is {
    [] -> []
    [x, ..rest_x] ->
      when ys is {
        [] -> []
        [y, ..rest_y] -> [f(x, y), ..map2(rest_x, rest_y, f)]
      }
  }
}

test map2_1() {
  map2([], [1, 2, 3], fn(a, b) { a + b }) == []
}

test map2_2() {
  map2([1, 2, 3], [1, 2], fn(a, b) { a + b }) == [2, 4]
}

// TODO: acceptance_test 024
//
// test map2_3() {
//   map2([42], [1, 2, 3], fn(_a, b) { Some(b) }) == [Some(1)]
// }

/// Apply a function of three arguments, combining elements from three lists.
///
/// Note: if one list is longer, the extra elements are dropped.
pub fn map3(
  xs: List<a>,
  ys: List<b>,
  zs: List<c>,
  f: fn(a, b, c) -> result,
) -> List<result> {
  when xs is {
    [] -> []
    [x, ..rest_x] ->
      when ys is {
        [] -> []
        [y, ..rest_y] ->
          when zs is {
            [] -> []
            [z, ..rest_z] -> [f(x, y, z), ..map3(rest_x, rest_y, rest_z, f)]
          }
      }
  }
}

test map3_1() {
  map3([], [], [1, 2, 3], fn(a, b, c) { a + b + c }) == []
}

test map3_2() {
  map3([1, 2, 3], [1, 2], [1, 2, 3], fn(a, b, c) { a + b + c }) == [3, 6]
}

/// Construct a list of a integer from a given range.
pub fn range(from: Int, to: Int) -> List<Int> {
  if from > to {
    []
  } else {
    [from, ..range(from + 1, to)]
  }
}

test range_1() {
  range(0, 3) == [0, 1, 2, 3]
}

test range_2() {
  range(-1, 1) == [-1, 0, 1]
}

/// Construct a list filled with n copies of a value.
pub fn repeat(x: a, n: Int) -> List<a> {
  if n <= 0 {
    []
  } else {
    [x, ..repeat(x, n - 1)]
  }
}

test repeat_1() {
  repeat(42, 0) == []
}

test repeat_2() {
  repeat(14, 3) == [14, 14, 14]
}

/// Get the number of elements in the given list.
pub fn reverse(xs: List<a>) -> List<a> {
  foldl(xs, fn(x, rest) { [x, ..rest] }, [])
}

test reverse_1() {
  reverse([]) == []
}

test reverse_2() {
  reverse([1, 2, 3]) == [3, 2, 1]
}

/// Get elements of a list after the first one, if any
pub fn tail(xs: List<a>) -> Option<List<a>> {
  when xs is {
    [] -> None
    [_, ..rest] -> Some(rest)
  }
}

test tail_1() {
  tail([1, 2, 3]) == Some([2, 3])
}

test tail_2() {
  tail([]) == None
}

/// Get the first `n` elements of a list.
pub fn take(xs: List<a>, n: Int) -> List<a> {
  if n <= 0 {
    []
  } else {
    when xs is {
    [] -> []
    [x, ..rest] -> [x, ..take(rest, n - 1)]
  }
  }
}

test take_1() {
  take([], 42) == []
}

test take_2() {
  take([1, 2, 3], 2) == [1, 2]
}

// /// Removes duplicate elements from a list.
// ///
// /// ```aiken
// /// use aiken/list
// ///
// /// list.unique([1,2,3,1])
// /// // [1,2,3]
// /// ```
// pub fn unique(xs: List<a>) -> List<a> {
//   when xs is {
//     [] -> []
//     [x, ..rest] -> [x, ..unique(filter(rest, fn(y) { y != x }))]
//   }
// }
//
// TODO: acceptance test 028
//
// test unique_1() {
//   unique([]) == []
// }
//
// test unique_2() {
//   let xs = [1, 2, 3, 1, 1, 3, 4, 1, 2, 3, 2, 4, 5, 6, 7, 8, 9, 10, 9]
//   unique(xs) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
// }

/// Decompose a list of tuples into a tuple of lists.
pub fn unzip(xs: List<#(a, b)>) -> #(List<a>, List<b>) {
  when xs is {
    [] -> #([], [])
    [#(a, b), ..rest] -> {
      let #(a_tail, b_tail) = unzip(rest)
      #([a, ..a_tail], [b, ..b_tail])
    }
  }
}

// TODO: acceptance_test 013
//
//test unzip_1() {
//  unzip([]) == #([], [])
//}
//
//test unzip_2() {
//  unzip([#(1, "a"), #(2, "b")]) == #([1, 2], ["a", "b"])
//}

/// Combine two lists together.
///
/// Note: if one list is longer, the extra elements are dropped.
pub fn zip(xs: List<a>, ys: List<b>) -> List<#(a, b)> {
  when xs is {
    [] -> []
    [x, ..rest_x] ->
      when ys is {
        [] -> []
        [y, ..rest_y] -> [#(x, y), ..zip(rest_x, rest_y)]
      }
  }
}

test zip_1() {
  zip([], [1, 2, 3]) == []
}

test zip_2() {
  zip([1, 2, 3], []) == []
}

test zip_3() {
  zip([1, 2], ["a", "b", "c"]) == [#(1, "a"), #(2, "b")]
}
