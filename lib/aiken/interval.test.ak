use aiken/fuzz.{and_then, both, constant, either}
use aiken/interval.{
  Finite, Interval, IntervalBound, IntervalBoundType, NegativeInfinity,
  PositiveInfinity,
}

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
  let it1 = interval.intersection(a, b)
  let it2 = interval.intersection(b, a)
  and {
    inclusive_lower_bound(it1.lower_bound) == inclusive_lower_bound(
      it2.lower_bound,
    ),
    inclusive_upper_bound(it1.upper_bound) == inclusive_upper_bound(
      it2.upper_bound,
    ),
  }
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
  and {
    interval.includes(a, intersection),
    interval.includes(b, intersection),
  }
}

test prop_includes_intersection_reg() {
  let a =
    Interval {
      lower_bound: IntervalBound {
        bound_type: interval.Finite(41),
        is_inclusive: True,
      },
      upper_bound: IntervalBound {
        bound_type: interval.PositiveInfinity,
        is_inclusive: True,
      },
    }
  let b =
    Interval {
      lower_bound: IntervalBound {
        bound_type: interval.Finite(41),
        is_inclusive: False,
      },
      upper_bound: IntervalBound {
        bound_type: interval.Finite(42),
        is_inclusive: True,
      },
    }

  let intersection = interval.intersection(a, b)

  (intersection == b)? || interval.is_empty(intersection)?
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

fn inclusive_lower_bound(
  IntervalBound { bound_type, is_inclusive }: IntervalBound,
) -> IntervalBoundType {
  if is_inclusive {
    bound_type
  } else {
    when bound_type is {
      Finite(x) -> Finite(x + 1)
      NegativeInfinity | PositiveInfinity -> bound_type
    }
  }
}

fn inclusive_upper_bound(
  IntervalBound { bound_type, is_inclusive }: IntervalBound,
) -> IntervalBoundType {
  if is_inclusive {
    bound_type
  } else {
    when bound_type is {
      Finite(x) -> Finite(x - 1)
      NegativeInfinity | PositiveInfinity -> bound_type
    }
  }
}
