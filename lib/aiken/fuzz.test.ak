use aiken/collection/list
use aiken/fuzz.{
  and_then, bool, constant, either3, either4, either5, either6, either7, either8,
  either9, int, int_between, label, list_between, list_with_elem, map, one_of,
  set, set_between, sublist, such_that,
}
use aiken/math
use aiken/primitive/bytearray
use aiken/primitive/string

test prop_int_distribution(n via int()) {
  label(
    if n < -255 {
      fail @"n < -max_u8"
    } else if n < 0 {
      @"[-255; 0["
    } else if n == 0 {
      @"0"
    } else if n < 256 {
      @"]0; 255]"
    } else if n < 16383 {
      @"[256; 16383]"
    } else {
      fail @"n > 16383"
    },
  )

  True
}

test prop_int_between_distribution(n via int_between(-100, 100)) {
  buckets(n, -100, 100, fn(n) { n + 25 })
  n >= -100 && n <= 100
}

test prop_int_between_large(
  n via int_between(0, 340_282_366_920_938_463_463_374_607_431_768_211_455),
) fail {
  n <= 18_446_744_073_709_551_615
}

test prop_bytearray_simplify(bytes via fuzz.bytearray()) fail once {
  bytes == ""
}

test prop_bool_distribution(is_true via bool()) {
  label(
    if is_true {
      @"True"
    } else {
      @"False"
    },
  )

  True
}

test prop_list_distribution_small(xs via list_between(int(), 0, 10)) {
  let len = list.length(xs)
  buckets(len, 0, 11, fn(n) { n + 1 })
  len >= 0 && len <= 10
}

fn is_even(x: Int) -> Bool {
  x % 2 == 0
}

test prop_such_that(x via such_that(int(), is_even)) {
  is_even(x)
}

test prop_list_exactly(xs via list_between(int(), 3, 3)) {
  list.length(xs) == 3
}

fn list_at_least() -> Fuzzer<(Int, List<Int>)> {
  let min <- and_then(int_between(0, 30))
  let xs <- map(fuzz.list_at_least(int(), min))
  (min, xs)
}

test prop_list_at_least(params via list_at_least()) {
  let (min, xs) = params
  list.length(xs) >= min
}

fn list_at_most() -> Fuzzer<(Int, List<Int>)> {
  let max <- and_then(int_between(-10, 10))
  let xs <- map(fuzz.list_at_most(int(), max))
  (max, xs)
}

test prop_list_at_most(params via list_at_most()) {
  let (max, xs) = params
  list.length(xs) <= math.max(0, max)
}

fn int_at_least() -> Fuzzer<(Int, Int)> {
  let min <- and_then(int())
  let n <- map(fuzz.int_at_least(min))
  (min, n)
}

test prop_int_at_least(params via int_at_least()) {
  let (min, n) = params
  n >= min
}

fn int_at_most() -> Fuzzer<(Int, Int)> {
  let max <- and_then(int())
  let n <- map(fuzz.int_at_most(max))
  (max, n)
}

test prop_int_at_most(params via int_at_most()) {
  let (max, n) = params
  n <= max
}

test prop_list_with_elem(xs via list_with_elem(int())) {
  let (xs, x) = xs
  list.has(xs, x)
}

fn list_with_sublist() -> Fuzzer<(List<Int>, List<Int>)> {
  let xs <- and_then(fuzz.list(int()))
  let sub <- map(sublist(xs))
  (xs, sub)
}

test prop_list_with_subset(params via list_with_sublist()) {
  let (xs, sub) = params
  list.all(sub, fn(x) { list.has(xs, x) })
}

fn bytearray_between() -> Fuzzer<(Int, Int, ByteArray)> {
  let min <- and_then(int_between(0, 50))
  let max <- and_then(int_between(min, 5 * min))
  let bytes <- map(fuzz.bytearray_between(min, max))
  (min, max, bytes)
}

test prop_bytearray_between(params via bytearray_between()) {
  let (min, max, bytes) = params

  let len = bytearray.length(bytes)

  let mid = ( min + max ) / 2

  label(
    if len < min {
      @"< min (impossible)"
    } else if len <= mid {
      @"<= mid (~50%)"
    } else if len <= max {
      @"<= max (~50%)"
    } else {
      @"> max (impossible)"
    },
  )

  len >= min && len <= max
}

test prop_int_between_boundary_up(n via int_between(0, 2)) fail once {
  n < 2
}

test prop_int_between_smallest_range(n via int_between(0, 1)) {
  label(
    if n == 0 {
      @"= 0"
    } else {
      @"= 1"
    },
  )
  n == 0 || n == 1
}

test prop_int_between_boundary_down(n via int_between(0, 10)) fail once {
  n > 0
}

test prop_one_of_upper(i via one_of([1, 3, 5, 7])) fail once {
  i != 7
}

test prop_set(xs via set(int())) {
  let ys =
    list.reduce(
      xs,
      [],
      fn(known, x) {
        expect !list.has(known, x)
        [x, ..known]
      },
    )

  list.length(ys) == list.length(xs)
}

test prop_set_between_distribution(n via set_between(int_between(0, 50), 3, 13)) {
  let len = n |> list.length
  label(len |> string.from_int)
  True
}

// This property simply illustrate a case where the `set`
// fuzzer would fail and not loop forever after not being
// able to satisfy the demand (not enough entropy in the
// input domain).
//
// test prop_set_exhausted(xs via set(int_between(0, 3))) {
//   True
// }

test prop_either3(
  lbl via either3(constant(@"a"), constant(@"b"), constant(@"c")),
) {
  label(lbl)
}

test prop_either4(
  lbl via either4(
    constant(@"a"),
    constant(@"b"),
    constant(@"c"),
    constant(@"d"),
  ),
) {
  label(lbl)
}

test prop_either5(
  lbl via either5(
    constant(@"a"),
    constant(@"b"),
    constant(@"c"),
    constant(@"d"),
    constant(@"e"),
  ),
) {
  label(lbl)
}

test prop_either6(
  lbl via either6(
    constant(@"a"),
    constant(@"b"),
    constant(@"c"),
    constant(@"d"),
    constant(@"e"),
    constant(@"f"),
  ),
) {
  label(lbl)
}

test prop_either7(
  lbl via either7(
    constant(@"a"),
    constant(@"b"),
    constant(@"c"),
    constant(@"d"),
    constant(@"e"),
    constant(@"f"),
    constant(@"g"),
  ),
) {
  label(lbl)
}

test prop_either8(
  lbl via either8(
    constant(@"a"),
    constant(@"b"),
    constant(@"c"),
    constant(@"d"),
    constant(@"e"),
    constant(@"f"),
    constant(@"g"),
    constant(@"h"),
  ),
) {
  label(lbl)
}

test prop_either9(
  lbl via either9(
    constant(@"a"),
    constant(@"b"),
    constant(@"c"),
    constant(@"d"),
    constant(@"e"),
    constant(@"f"),
    constant(@"g"),
    constant(@"h"),
    constant(@"i"),
  ),
) {
  label(lbl)
}

/// A small function for automatically labelling a range of ints.
fn buckets(n, start, end, increment) -> Void {
  expect n >= start
  let next = increment(start)
  if next >= end {
    label(
      [string.from_int(start), @"->", string.from_int(end)]
        |> string.join(@" "),
    )
  } else if n < next {
    label(
      [string.from_int(start), @"->", string.from_int(next)]
        |> string.join(@" "),
    )
  } else {
    buckets(n, next, end, increment)
  }
}
