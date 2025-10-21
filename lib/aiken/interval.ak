//// In a eUTxO-based blockchain like Cardano, the management of time can be
//// finicky.
////
//// Indeed, in order to maintain a complete determinism in the execution of
//// scripts, it is impossible to introduce a notion of _"current time"_ since
//// the execution would then depend on factor that are external to the
//// transaction itself: the ineluctable stream of time flowing in our universe.
////
//// Hence, to work around that, we typically define time intervals, which gives
//// window -- a.k.a intervals -- within which the transaction can be executed.
//// From within a script, it isn't possible to know when exactly the script is
//// executed, but we can reason about the interval bounds to validate pieces of
//// logic.
////
//// ## Example
////
//// Let's consider an example and assume an auction with a bidding period over
//// an interval $biddingPeriod = [start_{bid}, end_{bid})$.
////
//// - Bidders for the auction must be whitelisted by an administrator before the
//// bidding period starts.
////
//// - Once the bidding period is over, the auction winner may collect its due by
//// paying the agreed price.
////
//// This scenario identifies three periods:
////
//// ```
////    pre-bidding            bidding            post-bidding
//// -----------------[-----------------------)----------------->
////              start_bid                end_bid
//// ```
////
//// If we call $validityRange = [start_{tx}, end_{tx})$ the validity interval
//// of transactions during each period, we must then have:
////
//// > [!TIP]
//// > In Plutus V3, transaction validity ranges are always semi-open intervals, open in their upper bound.
////
//// 1. Pre-bidding: $end_{tx} \lt start_{bid}$
////
////    ```aiken
////    validity_range |> interval.is_entirely_before(start_bid)
////    ```
////
//// 2. Bidding: $validityRange \subseteq biddingPeriod$
////
////    ```aiken
////    bidding_period |> interval.includes(validity_range)
////    ```
////
////    or alternatively $start_{tx} \geq start_{bid}$ and $end_{tx} \lt end_{bid}$:
////
////    ```aiken
////    and {
////      bidding_period |> interval.contains(start_tx),
////      bidding_period |> interval.contains(end_tx),
////    }
////    ```
////
//// 3. Post-bidding: $start_{tx} \gt end_{bid}$
////
////    ```aiken
////    validity_range |> interval.is_entirely_after(end_bid)
////    ```

use aiken/primitive/int
use aiken/primitive/string

// By convention, infinites are inclusive
const positive_infinity: IntervalBound =
  IntervalBound { bound_type: PositiveInfinity, is_inclusive: True }

// By convention, infinites are inclusive
const negative_infinity: IntervalBound =
  IntervalBound { bound_type: NegativeInfinity, is_inclusive: True }

///
/// A type to represent intervals of values. Interval are inhabited by an
/// integer value representing  have a finite lower-bound and/or upper-bound.
///
/// This allows to represent all kind of mathematical intervals:
///
/// ```aiken
/// // [1; 10]
/// let i0: Interval = Interval
///   { lower_bound:
///       IntervalBound { bound_type: Finite(1), is_inclusive: True }
///   , upper_bound:
///       IntervalBound { bound_type: Finite(10), is_inclusive: True }
///   }
/// ```
///
/// ```aiken
/// // (20; infinity)
/// let i1: Interval = Interval
///   { lower_bound:
///       IntervalBound { bound_type: Finite(20), is_inclusive: False }
///   , upper_bound:
///       IntervalBound { bound_type: PositiveInfinity, is_inclusive: False }
///   }
/// ```
pub type Interval {
  lower_bound: IntervalBound,
  upper_bound: IntervalBound,
}

/// An interval bound, either inclusive or exclusive.
pub type IntervalBound {
  bound_type: IntervalBoundType,
  is_inclusive: Bool,
}

/// A type of interval bound. The value for the `Finite` case typically
/// represents a number of seconds or milliseconds.
pub type IntervalBoundType {
  NegativeInfinity
  Finite(Int)
  PositiveInfinity
}

// ## Constructing

/// Create an interval that includes all values greater than the given bound. i.e $[lower_bound, +∞]$
///
/// ```aiken
/// interval.after(10) == Interval {
///   lower_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
///   upper_bound: IntervalBound { bound_type: PositiveInfinity, is_inclusive: True },
/// }
/// ```
pub fn after(lower_bound: Int) -> Interval {
  Interval {
    lower_bound: IntervalBound {
      bound_type: Finite(lower_bound),
      is_inclusive: True,
    },
    upper_bound: positive_infinity,
  }
}

/// Create an interval that includes all values after (and not including) the given bound. i.e $(lower_bound, +∞]$
///
/// ```aiken
/// interval.entirely_after(10) == Interval {
///   lower_bound: IntervalBound { bound_type: Finite(10), is_inclusive: False },
///   upper_bound: IntervalBound { bound_type: PositiveInfinity, is_inclusive: True },
/// }
/// ```
pub fn entirely_after(lower_bound: Int) -> Interval {
  Interval {
    lower_bound: IntervalBound {
      bound_type: Finite(lower_bound),
      is_inclusive: False,
    },
    upper_bound: positive_infinity,
  }
}

/// Create an interval that includes all values before (and including) the given bound. i.e $(-∞, upper_bound]$
///
/// ```aiken
/// interval.before(100) == Interval {
///   lower_bound: IntervalBound { bound_type: NegativeInfinity, is_inclusive: True },
///   upper_bound: IntervalBound { bound_type: Finite(100), is_inclusive: True },
/// }
/// ```
pub fn before(upper_bound: Int) -> Interval {
  Interval {
    lower_bound: negative_infinity,
    upper_bound: IntervalBound {
      bound_type: Finite(upper_bound),
      is_inclusive: True,
    },
  }
}

/// Create an interval that includes all values before (and not including) the given bound. i.e $(-∞, upper_bound)$
///
/// ```aiken
/// interval.entirely_before(10) == Interval {
///   lower_bound: IntervalBound { bound_type: NegativeInfinity, is_inclusive: True },
///   upper_bound: IntervalBound { bound_type: Finite(10), is_inclusive: False },
/// }
/// ```
pub fn entirely_before(upper_bound: Int) -> Interval {
  Interval {
    lower_bound: negative_infinity,
    upper_bound: IntervalBound {
      bound_type: Finite(upper_bound),
      is_inclusive: False,
    },
  }
}

/// Create an interval that includes all values between two bounds, including the bounds. i.e. $[lower_bound, upper_bound]$
///
/// ```aiken
/// interval.between(10, 100) == Interval {
///   lower_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
///   upper_bound: IntervalBound { bound_type: Finite(100), is_inclusive: True },
/// }
/// ```
pub fn between(lower_bound: Int, upper_bound: Int) -> Interval {
  Interval {
    lower_bound: IntervalBound {
      bound_type: Finite(lower_bound),
      is_inclusive: True,
    },
    upper_bound: IntervalBound {
      bound_type: Finite(upper_bound),
      is_inclusive: True,
    },
  }
}

/// Create an interval that includes all values between two bounds, excluding the bounds. i.e. $(lower_bound, upper_bound)$
///
/// ```aiken
/// interval.entirely_between(10, 100) == Interval {
///   lower_bound: IntervalBound { bound_type: Finite(10), is_inclusive: False },
///   upper_bound: IntervalBound { bound_type: Finite(100), is_inclusive: False },
/// }
/// ```
pub fn entirely_between(lower_bound: Int, upper_bound: Int) -> Interval {
  Interval {
    lower_bound: IntervalBound {
      bound_type: Finite(lower_bound),
      is_inclusive: False,
    },
    upper_bound: IntervalBound {
      bound_type: Finite(upper_bound),
      is_inclusive: False,
    },
  }
}

/// Create an empty interval that contains no value.
///
/// ```aiken
/// interval.contains(empty, 0) == False
/// interval.contains(empty, 1000) == False
/// ```
pub const empty: Interval =
  Interval { lower_bound: positive_infinity, upper_bound: negative_infinity }

/// Create an interval that contains every possible values. i.e. $(-∞, +∞)$
///
/// ```aiken
/// interval.contains(everything, 0) == True
/// interval.contains(everything, 1000) == True
/// ```
pub const everything: Interval =
  Interval { lower_bound: negative_infinity, upper_bound: positive_infinity }

// ## Inspecting

/// Checks whether an element is contained within the interval.
///
/// ```aiken
/// let iv =
///   Interval {
///     lower_bound: IntervalBound {
///       bound_type: Finite(14),
///       is_inclusive: True
///     },
///     upper_bound: IntervalBound {
///       bound_type: Finite(42),
///       is_inclusive: False
///     },
///   }
///
/// interval.contains(iv, 25) == True
/// interval.contains(iv, 0) == False
/// interval.contains(iv, 14) == True
/// interval.contains(iv, 42) == False
/// ```
pub fn contains(self: Interval, elem: Int) -> Bool {
  let is_greater_than_lower_bound =
    when self.lower_bound.bound_type is {
      NegativeInfinity -> True
      Finite(lower_bound) ->
        if self.lower_bound.is_inclusive {
          elem >= lower_bound
        } else {
          elem > lower_bound
        }
      PositiveInfinity -> False
    }

  let is_smaller_than_upper_bound =
    when self.upper_bound.bound_type is {
      NegativeInfinity -> False
      Finite(upper_bound) ->
        if self.upper_bound.is_inclusive {
          elem <= upper_bound
        } else {
          elem < upper_bound
        }
      PositiveInfinity -> True
    }

  is_greater_than_lower_bound && is_smaller_than_upper_bound
}

test contains_1() {
  let iv = everything
  contains(iv, 14)
}

test contains_2() {
  let iv = entirely_before(15)
  contains(iv, 14)
}

test contains_3() {
  let iv = before(14)
  contains(iv, 14)
}

test contains_4() {
  let iv = entirely_before(14)
  !contains(iv, 14)
}

test contains_5() {
  let iv = entirely_after(13)
  contains(iv, 14)
}

test contains_6() {
  let iv = after(14)
  contains(iv, 14)
}

test contains_7() {
  let iv = entirely_after(14)
  !contains(iv, 14)
}

test contains_8() {
  let iv = between(42, 1337)
  !contains(iv, 14)
}

test contains_9() {
  let iv = between(0, 42)
  contains(iv, 14)
}

test contains_10() {
  let iv = between(0, 42)
  contains(iv, 42)
}

test contains_11() {
  let iv = entirely_between(0, 42)
  !contains(iv, 0)
}

test contains_12() {
  let iv = empty
  !contains(iv, 14)
}

/// Tells whether an interval is empty; i.e. that is contains no value.
///
/// ```aiken
/// let iv1 = interval.empty
///
/// let iv2 = Interval {
///     lower_bound: IntervalBound { bound_type: Finite(0), is_inclusive: False },
///     upper_bound: IntervalBound { bound_type: Finite(0), is_inclusive: False },
///   }
///
/// let iv3 = Interval {
///     lower_bound: IntervalBound { bound_type: Finite(0), is_inclusive: False },
///     upper_bound: IntervalBound { bound_type: Finite(100), is_inclusive: False },
///   }
///
/// interval.is_empty(iv1) == True
/// interval.is_empty(iv2) == True
/// interval.is_empty(iv3) == False
///
/// // Note: Two empty intervals are not necessarily equal.
/// iv1 != iv2
/// ```
pub fn is_empty(Interval { lower_bound, upper_bound }: Interval) -> Bool {
  when lower_bound.bound_type is {
    NegativeInfinity -> False
    PositiveInfinity -> upper_bound.bound_type != PositiveInfinity
    Finite(l) ->
      when upper_bound.bound_type is {
        NegativeInfinity -> True
        Finite(r) -> {
          let l =
            if lower_bound.is_inclusive {
              l
            } else {
              l + 1
            }
          if upper_bound.is_inclusive {
            l > r
          } else {
            l >= r
          }
        }
        PositiveInfinity -> False
      }
  }
}

/// Check whether the interval is entirely after a given point.
///
/// ```aiken
/// interval.is_entirely_after(interval.after(10), 5) == True
/// interval.is_entirely_after(interval.after(10), 10) == False
/// interval.is_entirely_after(interval.after(10), 15) == False
/// interval.is_entirely_after(interval.between(10, 20), 30) == False
/// interval.is_entirely_after(interval.between(10, 20), 5) == True
/// ```
pub fn is_entirely_after(self: Interval, point: Int) -> Bool {
  when self.lower_bound.bound_type is {
    Finite(low) ->
      if self.lower_bound.is_inclusive {
        point < low
      } else {
        point <= low
      }
    NegativeInfinity -> False
    PositiveInfinity -> True
  }
}

test is_entirely_after_1() {
  is_entirely_after(after(10), 5)
}

test is_entirely_after_2() {
  !is_entirely_after(after(10), 10)
}

test is_entirely_after_3() {
  !is_entirely_after(after(10), 15)
}

test is_entirely_after_4() {
  !is_entirely_after(between(10, 20), 30)
}

test is_entirely_after_5() {
  is_entirely_after(between(10, 20), 5)
}

test is_entirely_after_6() {
  is_entirely_after(entirely_after(10), 10)
}

test is_entirely_after_7() {
  !is_entirely_after(before(10), 5)
}

test is_entirely_after_8() {
  !is_entirely_after(before(10), 15)
}

test is_entirely_after_9() {
  !is_entirely_after(entirely_before(10), 5)
}

test is_entirely_after_10() {
  is_entirely_after(
    Interval {
      lower_bound: IntervalBound {
        bound_type: PositiveInfinity,
        is_inclusive: True,
      },
      upper_bound: IntervalBound {
        bound_type: PositiveInfinity,
        is_inclusive: False,
      },
    },
    1,
  )
}

/// Check whether the interval is entirely before a given point.
///
/// ```aiken
/// interval.is_entirely_before(interval.before(10), 15) == True
/// interval.is_entirely_before(interval.before(10), 10) == False
/// interval.is_entirely_before(interval.before(10), 5) == False
/// interval.is_entirely_before(interval.between(10, 20), 30) == True
/// interval.is_entirely_before(interval.between(10, 20), 5) == False
/// ```
pub fn is_entirely_before(self: Interval, point: Int) -> Bool {
  when self.upper_bound.bound_type is {
    Finite(hi) ->
      if self.upper_bound.is_inclusive {
        hi < point
      } else {
        hi <= point
      }
    PositiveInfinity -> False
    NegativeInfinity -> True
  }
}

test is_entirely_before_1() {
  is_entirely_before(before(10), 15)
}

test is_entirely_before_2() {
  !is_entirely_before(before(10), 10)
}

test is_entirely_before_3() {
  !is_entirely_before(before(10), 5)
}

test is_entirely_before_4() {
  is_entirely_before(between(10, 20), 30)
}

test is_entirely_before_5() {
  !is_entirely_before(between(10, 20), 5)
}

test is_entirely_before_6() {
  is_entirely_before(entirely_before(10), 10)
}

test is_entirely_before_7() {
  !is_entirely_before(after(10), 15)
}

test is_entirely_before_8() {
  !is_entirely_before(after(10), 5)
}

test is_entirely_before_9() {
  !is_entirely_before(entirely_after(10), 5)
}

test is_entirely_before_10() {
  is_entirely_before(
    Interval {
      lower_bound: IntervalBound {
        bound_type: NegativeInfinity,
        is_inclusive: True,
      },
      upper_bound: IntervalBound {
        bound_type: NegativeInfinity,
        is_inclusive: False,
      },
    },
    1,
  )
}

/// Obtain a human-readable string representation of the interval. Useful for debugging.
pub fn to_string(self: Interval) -> String {
  let lower_bracket =
    if self.lower_bound.is_inclusive {
      @"["
    } else {
      @"("
    }

  let lower_bound = bound_type_to_string(self.lower_bound.bound_type)

  let upper_bound = bound_type_to_string(self.upper_bound.bound_type)

  let upper_bracket =
    if self.upper_bound.is_inclusive {
      @"]"
    } else {
      @")"
    }

  lower_bracket
    |> string.concat(lower_bound)
    |> string.concat(@", ")
    |> string.concat(upper_bound)
    |> string.concat(upper_bracket)
}

fn bound_type_to_string(self: IntervalBoundType) -> String {
  when self is {
    NegativeInfinity -> @"-∞"
    Finite(i) -> string.from_int(i)
    PositiveInfinity -> @"+∞"
  }
}

// ## Combining

/// Computes the smallest interval containing the two given intervals, if any
///
/// ```aiken
/// let iv1 = between(0, 10) // [0, 10]
/// let iv2 = between(2, 14) // [2, 14]
/// hull(iv1, iv2) == between(0, 14)
///
/// let iv1 = between(5, 10) // [5, 10]
/// let iv2 = before(0) // [ْ-∞, 0]
/// hull(iv1, iv2) == before(10)
///
/// let iv1 = entirely_after(0) // (0, +∞]
/// let iv2 = between(10, 42)  // [10, 42]
/// hull(iv1, iv2) = entirely_after(0)
/// ```
pub fn hull(iv1: Interval, iv2: Interval) -> Interval {
  Interval {
    lower_bound: min(iv1.lower_bound, iv2.lower_bound, inclusive_lower_bound),
    upper_bound: max(iv1.upper_bound, iv2.upper_bound, inclusive_upper_bound),
  }
}

test hull_1() {
  let iv1 = between(0, 10)
  let iv2 = between(2, 14)
  hull(iv1, iv2) == between(0, 14)
}

test hull_2() {
  let iv1 = between(5, 10)
  let iv2 = before(0)
  hull(iv1, iv2) == before(10)
}

test hull_3() {
  let iv1 = entirely_after(0)
  let iv2 = between(10, 42)
  hull(iv1, iv2) == entirely_after(0)
}

/// Checks whether the second interval is fully included in the first.
///
/// ```aiken
/// between(-5, 5)  // [-5, 5]
///   |> includes(between(0, 2)) // [0, 2]
///
/// between(-5, 5)  // [-5, 5]
///   |> includes(entirely_between(-5, 5)) // (-5, 5)
///
/// after(0) // [0, +∞]
///   |> includes(after(1)) // [1, +∞]
///
/// before(-1) // (-∞, -1]
///   |> includes(entirely_before(-1)) // [-∞, -1)
/// ```
pub fn includes(self: Interval, other: Interval) -> Bool {
  if is_empty(other) {
    True
  } else if is_empty(self) {
    False
  } else {
    and {
      compare_bound(self.lower_bound, other.lower_bound, inclusive_lower_bound) != Greater,
      compare_bound(self.upper_bound, other.upper_bound, inclusive_upper_bound) != Less,
    }
  }
}

// contains :: (Enum a, Ord a) => Interval a -> Interval a -> Bool
// -- Everything contains the empty interval
// contains _ i2 | isEmpty i2 = True
// -- Nothing is contained in the empty interval (except the empty interval,
// -- which is already handled)
// contains i1 _ | isEmpty i1 = False
// -- Otherwise we check the endpoints. This doesn't work for empty intervals,
// -- hence the cases above.
// contains (Interval l1 h1) (Interval l2 h2) = l1 <= l2 && h2 <= h1
// {-# INLINABLE contains #-}

test includes_1() {
  between(-5, 5) |> includes(between(-5, 5))
}

test includes_2() {
  between(-5, 5) |> includes(between(0, 2))
}

test includes_3() {
  between(-5, 5) |> includes(entirely_between(-5, 5))
}

test includes_4() {
  !(entirely_between(-5, 5) |> includes(between(-5, 5)))
}

test includes_5() {
  and {
    after(0) |> includes(after(1)),
    entirely_after(0) |> includes(entirely_after(1)),
  }
}

test includes_6() {
  and {
    after(0) |> includes(after(1)),
    entirely_after(0) |> includes(after(1)),
  }
}

test includes_7() {
  and {
    before(0) |> includes(before(-1)),
    entirely_before(0) |> includes(before(-1)),
  }
}

test includes_8() {
  and {
    !(before(-1) |> includes(before(0))),
    !(entirely_before(-1) |> includes(before(0))),
  }
}

/// Computes the largest interval contained in the two given intervals, if any.
///
/// ```aiken
/// let iv1 = interval.between(0, 10) // [0, 10]
/// let iv2 = interval.between(2, 14) // [2, 14]
/// interval.intersection(iv1, iv2) == interval.between(2, 10)
///
/// let iv1 = interval.entirely_before(10) // [-∞, 10)
/// let iv2 = interval.entirely_after(0) // (0, +∞]
/// interval.intersection(iv1, iv2) == interval.entirely_between(0, 10)
///
/// let iv1 = interval.between(0, 1) // [0, 1]
/// let iv2 = interval.between(2, 3) // [2, 3]
/// interval.intersection(iv1, iv2) |> interval.is_empty
/// ```
pub fn intersection(iv1: Interval, iv2: Interval) -> Interval {
  Interval {
    lower_bound: max(iv1.lower_bound, iv2.lower_bound, inclusive_lower_bound),
    upper_bound: min(iv1.upper_bound, iv2.upper_bound, inclusive_upper_bound),
  }
}

test intersection_1() {
  let iv1 = between(0, 10)
  let iv2 = between(2, 14)
  intersection(iv1, iv2) == between(2, 10)
}

test intersection_2() {
  let iv1 = between(0, 1)
  let iv2 = between(1, 2)
  intersection(iv1, iv2) == between(1, 1)
}

test intersection_3() {
  let iv1 = between(0, 1)
  let iv2 = entirely_between(1, 2)
  intersection(iv1, iv2)
    |> is_empty
}

test intersection_4() {
  let iv1 = entirely_between(0, 1)
  let iv2 = entirely_between(1, 2)
  intersection(iv1, iv2)
    |> is_empty
}

test intersection_5() {
  let iv1 = between(0, 10)
  let iv2 = before(4)
  intersection(iv1, iv2) == between(0, 4)
}

test intersection_6() {
  let iv1 = entirely_before(10)
  let iv2 = entirely_after(0)
  intersection(iv1, iv2) == entirely_between(0, 10)
}

/// Return the highest bound of the two. For equal `IntervalBoundType`,
/// an inclusive `IntervalBound` is considered higher.
///
/// ```aiken
/// let ib1 = IntervalBound { bound_type: Finite(0), is_inclusive: False }
/// let ib2 = IntervalBound { bound_type: Finite(1), is_inclusive: False }
///
/// interval.max(ib1, ib2) == ib2
/// ```
fn max(
  left: IntervalBound,
  right: IntervalBound,
  to_inclusive: fn(IntervalBound) -> IntervalBoundType,
) -> IntervalBound {
  let ord = compare_bound_type(to_inclusive(left), to_inclusive(right))
  when ord is {
    Greater | Equal -> left
    Less -> right
  }
}

/// Return the smallest bound of the two. For equal `IntervalBoundType`,
/// an inclusive `IntervalBound` is considered smaller.
///
/// ```aiken
/// let ib1 = IntervalBound { bound_type: Finite(0), is_inclusive: False }
/// let ib2 = IntervalBound { bound_type: Finite(1), is_inclusive: False }
///
/// interval.min(ib1, ib2) == ib1
/// ```
fn min(
  left: IntervalBound,
  right: IntervalBound,
  to_inclusive: fn(IntervalBound) -> IntervalBoundType,
) -> IntervalBound {
  let ord = compare_bound_type(to_inclusive(left), to_inclusive(right))
  when ord is {
    Less | Equal -> left
    Greater -> right
  }
}

fn compare_bound(
  left: IntervalBound,
  right: IntervalBound,
  to_inclusive: fn(IntervalBound) -> IntervalBoundType,
) -> Ordering {
  compare_bound_type(to_inclusive(left), to_inclusive(right))
}

fn compare_bound_type(
  left: IntervalBoundType,
  right: IntervalBoundType,
) -> Ordering {
  when left is {
    NegativeInfinity ->
      when right is {
        NegativeInfinity -> Equal
        _ -> Less
      }
    PositiveInfinity ->
      when right is {
        PositiveInfinity -> Equal
        _ -> Greater
      }
    Finite(l) ->
      when right is {
        NegativeInfinity -> Greater
        Finite(r) -> int.compare(l, r)
        PositiveInfinity -> Less
      }
  }
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
