use aiken/fuzz.{and_then, both, constant, either}
use aiken/interval.{Interval, IntervalBound, IntervalBoundType}

const bound_type: Fuzzer<IntervalBoundType> =
  fuzz.either(
    fuzz.map(fuzz.int(), IntervalBoundType.Finite),
    either(
      constant(IntervalBoundType.NegativeInfinity),
      constant(IntervalBoundType.PositiveInfinity),
    ),
  )

const bound: Fuzzer<IntervalBound> =
  fuzz.map2(bound_type, fuzz.bool(), IntervalBound)

const interval: Fuzzer<Interval> = {
    let roll <- and_then(fuzz.byte())
    if roll < 220 {
      fuzz.map2(bound, bound, Interval)
        |> fuzz.such_that(fn(itv) { !interval.is_empty(itv) })
    } else {
      fuzz.map2(bound, bound, Interval)
    }
  }

test prop_intersection_symmetric((a, b) via both(interval, interval)) {
  interval.intersection(a, b) == interval.intersection(b, a)
}

test prop_intersection_idempotent((a, b) via both(interval, interval)) {
  let intersection = interval.intersection(a, b)
  interval.intersection(intersection, b) == intersection
}

test prop_intersection_everything_is_identity(itv via interval) {
  interval.intersection(itv, interval.everything) == itv
}

test prop_intersection_empty_is_empty(itv via interval) {
  interval.intersection(itv, interval.empty) |> interval.is_empty
}

test prop_includes_intersection((a, b) via both(interval, interval)) {
  let intersection = interval.intersection(a, b)
  if interval.includes(a, b) {
    fuzz.label(@"includes")
    intersection == b || interval.is_empty(intersection)
  } else {
    fuzz.label(@"excludes")
    True
  }
}

const fixture_intersection_contains: Fuzzer<(Interval, Interval, Int)> = {
    let a <- and_then(interval)
    let b <- and_then(interval)
    let pt <- fuzz.map(fuzz.int())
    (a, b, pt)
  }

test prop_intersection_contains((a, b, pt) via fixture_intersection_contains) {
  let intersection = interval.intersection(a, b)
  if interval.contains(intersection, pt) {
    fuzz.label(@"contains")
    and {
      interval.contains(a, pt),
      interval.contains(b, pt),
    }
  } else {
    fuzz.label(@"not contains")
    True
  }
}

test prop_includes_itself(itv via interval) {
  interval.is_empty(itv) || interval.includes(itv, itv)
}

test prop_includes_empty(itv via interval) {
  let is_empty = interval.is_empty(itv)
  fuzz.label_when(is_empty, @"empty", @"non-empty")
  is_empty || interval.includes(itv, interval.empty)
}
