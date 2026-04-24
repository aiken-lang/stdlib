use aiken/builtin

// ## Constructing

/// Add an element in front of the list. Sometimes useful when combined with
/// other functions.
///
/// ```aiken
/// list.push([2, 3], 1) == [1, ..[2, 3]] == [1, 2, 3]
/// ```
pub fn push(self: List<a>, elem: a) -> List<a> {
  [elem, ..self]
}

/// Construct a list of a integer from a given range.
///
/// ```aiken
/// list.range(0, 3) == [0, 1, 2, 3]
/// list.range(-1, 1) == [-1, 0, 1]
/// ```
pub fn range(from: Int, to: Int) -> List<Int> {
  if from > to {
    []
  } else {
    [from, ..range(from + 1, to)]
  }
}

/// Construct a list filled with n copies of a value.
///
/// ```aiken
/// list.repeat("na", 3) == ["na", "na", "na"]
/// ```
pub fn repeat(elem: a, n_times: Int) -> List<a> {
  if n_times <= 0 {
    []
  } else {
    [elem, ..repeat(elem, n_times - 1)]
  }
}

// ## Inspecting

/// Determine if all elements of the list satisfy the given predicate.
///
/// > [!NOTE]
/// > An empty list always satisfies the predicate.
///
/// ```aiken
/// list.all([], fn(n) { n > 0 }) == True
/// list.all([1, 2, 3], fn(n) { n > 0 }) == True
/// list.all([1, 2, 3], fn(n) { n == 2 }) == False
/// ```
pub fn all(self: List<a>, predicate: fn(a) -> Bool) -> Bool {
  when self is {
    [] -> True
    [x, ..xs] -> predicate(x) && all(xs, predicate)
  }
}

/// Determine if at least one element of the list satisfies the given predicate.
///
/// > [!NOTE]
/// > An empty list NEVER satisfies the predicate.
///
/// ```aiken
/// list.any([], fn(n) { n > 2 }) == False
/// list.any([1, 2, 3], fn(n) { n > 0 }) == True
/// list.any([1, 2, 3], fn(n) { n == 2 }) == True
/// list.any([1, 2, 3], fn(n) { n < 0 }) == False
/// ```
pub fn any(self: List<a>, predicate: fn(a) -> Bool) -> Bool {
  when self is {
    [] -> False
    [x, ..xs] -> predicate(x) || any(xs, predicate)
  }
}

/// Return `Some(item)` at the index or None if the index is out of range. The index is 0-based.
///
/// ```aiken
/// list.at([1, 2, 3], 1) == Some(2)
/// list.at([1, 2, 3], 42) == None
/// ```
pub fn at(self: List<a>, index: Int) -> Option<a> {
  if index < 0 {
    None
  } else {
    do_at(self, index)
  }
}

fn do_at(self: List<a>, index: Int) -> Option<a> {
  when self is {
    [] -> None
    [x, ..xs] ->
      if index == 0 {
        Some(x)
      } else {
        do_at(xs, index - 1)
      }
  }
}

/// Count how many items in the list satisfy the given predicate.
///
/// ```aiken
/// list.count([], fn(a) { a > 2}) == 0
/// list.count([1, 2, 3], fn(a) { n > 0 }) == 3
/// list.count([1, 2, 3], fn(a) { n >= 2 }) == 2
/// list.count([1, 2, 3], fn(a) { n > 5 }) == 0
/// ```
pub fn count(self: List<a>, predicate: fn(a) -> Bool) -> Int {
  foldr(
    self,
    0,
    fn(item, total) {
      if predicate(item) {
        total + 1
      } else {
        total
      }
    },
  )
}

/// Find the first element satisfying the given predicate, if any.
///
/// ```aiken
/// list.find([1, 2, 3], fn(x) { x == 2 }) == Some(2)
/// list.find([4, 5, 6], fn(x) { x == 2 }) == None
/// ```
pub fn find(self: List<a>, predicate: fn(a) -> Bool) -> Option<a> {
  when self is {
    [] -> None
    [x, ..xs] ->
      if predicate(x) {
        Some(x)
      } else {
        find(xs, predicate)
      }
  }
}

/// Like [`find`](#find), but maps the found element to something else. This
/// provides an efficient way to access and transform an element in a list.
///
/// ```aiken
/// expect Some(2) = list.find_map(["a", "bb", "ccc"], fn(x) {
///   let len = bytearray.length(x)
///   if len > 1 {
///     Some(len)
///   } else {
///     None
///   }
/// })
pub fn find_map(
  self: List<a>,
  predicate: fn(a) -> Option<result>,
) -> Option<result> {
  when self is {
    [] -> None
    [x, ..xs] -> {
      let result = predicate(x)
      if result != None {
        result
      } else {
        find_map(xs, predicate)
      }
    }
  }
}

/// Figures out whether a list contain the given element.
///
/// ```aiken
/// list.has([1, 2, 3], 2) == True
/// list.has([1, 2, 3], 14) == False
/// list.has([], 14) == False
/// ```
pub fn has(self: List<a>, elem: a) -> Bool {
  when self is {
    [] -> False
    [head, ..tail] -> head == elem || has(tail, elem)
  }
}

/// Get the first element of a list
///
/// ```aiken
/// list.head([1, 2, 3]) == Some(1)
/// list.head([]) == None
/// ```
pub fn head(self: List<a>) -> Option<a> {
  when self is {
    [] -> None
    _ -> Some(builtin.head_list(self))
  }
}

/// Checks whether a list is empty.
///
/// ```aiken
/// list.is_empty([]) == True
/// list.is_empty([1, 2, 3]) == False
/// ```
pub fn is_empty(self: List<a>) -> Bool {
  when self is {
    [] -> True
    _ -> False
  }
}

/// Gets the index of an element of a list, if any. Otherwise, returns None.
///
/// ```aiken
/// list.index_of([1, 5, 2], 2) == Some(2)
/// list.index_of([1, 7, 3], 4) == None
/// list.index_of([1, 0, 9, 6], 6) == Some(3)
/// list.index_of([], 6) == None
/// ```
pub fn index_of(self: List<a>, elem: a) -> Option<Int> {
  do_index_of(self, elem, 0)
}

fn do_index_of(self: List<a>, elem: a, i: Int) -> Option<Int> {
  when self is {
    [] -> None
    [x, ..xs] ->
      if x == elem {
        Some(i)
      } else {
        do_index_of(xs, elem, i + 1)
      }
  }
}

/// Get the last in the given list, if any.
///
/// ```aiken
/// list.last([]) == None
/// list.last([1, 2, 3]) == Some(3)
/// ```
pub fn last(self: List<a>) -> Option<a> {
  when self is {
    [] -> None
    [x] -> Some(x)
    [_, ..xs] -> last(xs)
  }
}

/// Get the number of elements in the given list.
///
/// ```aiken
/// list.length([]) == 0
/// list.length([1, 2, 3]) == 3
/// ```
pub fn length(self: List<a>) -> Int {
  when self is {
    [] -> 0
    [_, ..xs] -> 1 + length(xs)
  }
}

// ## Inspecting Forcibly

/// More efficient version of [`any`](#any), but fails if no element satisfies the predicate.
///
/// > [!NOTE]
/// > An empty list NEVER satisfies the predicate.
///
/// ```aiken
/// list.any([], fn(n) { n > 2 }) → 💥
/// list.any([1, 2, 3], fn(n) { n > 0 }) == True
/// list.any([1, 2, 3], fn(n) { n == 2 }) == True
/// list.any([1, 2, 3], fn(n) { n < 0 }) → 💥
/// ```
pub fn expect_any(self: List<a>, predicate: fn(a) -> Bool) -> Void {
  if predicate(builtin.head_list(self)) {
    Void
  } else {
    expect_any(builtin.tail_list(self), predicate)
  }
}

/// More efficient version of [`at`](#at), but fails if there's no element at the
/// given index (or if the index is out of bound).
///
/// ```aiken
/// list.expect_at([1, 2, 3], 1) == 2
/// list.expect_at([1, 2, 3], 42) → 💥
/// ```
pub fn expect_at(self: List<a>, index: Int) -> a {
  if index >= 2 {
    expect_at(builtin.tail_list(builtin.tail_list(self)), index - 2)
  } else {
    if index >= 1 {
      expect_at(builtin.tail_list(self), index - 1)
    } else {
      if index == 0 {
        builtin.head_list(self)
      } else {
        fail @"expect_at: not found"
      }
    }
  }
}

/// More efficient version of [`find`](#find), but fails if the element is not found.
///
/// ```aiken
/// list.expect_find([1, 2, 3], fn(x) { x == 2 }) == 2
/// list.expect_find([4, 5, 6], fn(x) { x == 2 }) → 💥
/// ```
pub fn expect_find(self: List<a>, predicate: fn(a) -> Bool) -> a {
  let elem = builtin.head_list(self)
  if predicate(elem) {
    elem
  } else {
    expect_find(builtin.tail_list(self), predicate)
  }
}

/// More efficient version of [`find_map`](#find_map) but fails if no element
/// is selected.
///
/// ```aiken
/// expect 2 = list.expect_find_map(["a", "bb", "ccc"], fn(x, keep, discard) {
///   let len = bytearray.length(x)
///   if len > 1 {
///     keep(len)
///   } else {
///     discard()
///   }
/// })
/// ```
pub fn expect_find_map(
  self: List<a>,
  select: fn(a, fn(b) -> b, fn() -> b) -> b,
) -> b {
  when self is {
    [] -> fail @"expect_find_map: not found"
    [head, ..tail] ->
      select(head, identity, fn() { expect_find_map(tail, select) })
  }
}

/// More efficient version of [`has`](#has) but fails if the element is missing.
///
/// ```aiken
/// list.expect_has([1, 2, 3], 2) → ✅
/// list.expect_has([1, 2, 3], 14) → 💥
/// list.expect_has([], 14) → 💥
/// ```
pub fn expect_has(self: List<a>, elem: a) -> Void {
  expect do_expect_has(self, elem)
}

fn do_expect_has(self: List<a>, elem: a) -> Bool {
  builtin.head_list(self) == elem || do_expect_has(
    builtin.tail_list(self),
    elem,
  )
}

/// More efficient version of [`head`](#head), but fails if the list is empty.
///
/// ```aiken
/// list.expect_head([1, 2, 3]) == 1
/// list.expect_head([]) → 💥
/// ```
pub fn expect_head(self: List<a>) -> a {
  builtin.head_list(self)
}

/// More efficient version of [`index_of`](#index_of), but fails if the element
/// is not in the list.
///
/// ```aiken
/// list.expect_index_of([1, 5, 2], 2) == 2
/// list.expect_index_of([1, 7, 3], 4) → 💥
/// list.expect_index_of([1, 0, 9, 6], 6) == 3
/// list.expect_index_of([], 6) → 💥
/// ```
pub fn expect_index_of(self: List<a>, elem: a) -> Int {
  if builtin.head_list(self) == elem {
    0
  } else {
    expect_index_of(builtin.tail_list(self), elem) + 1
  }
}

/// More efficient version of [`last`](#last), but fails when the list is empty.
///
/// ```aiken
/// list.expect_last([1, 2, 3]) == 3
/// list.expect_last([]) → 💥
/// ```
pub fn expect_last(self: List<a>) -> a {
  let tail = builtin.tail_list(self)
  when tail is {
    [] -> builtin.head_list(self)
    _ -> expect_last(tail)
  }
}

// ## Modifying

// ### Extracting

/// Remove the first occurrence of the given element from the list.
///
/// ```aiken
/// list.delete([1, 2, 3, 1], 1) == [2, 3, 1]
/// list.delete([1, 2, 3], 14) == [1, 2, 3]
/// ```
pub fn delete(self: List<a>, elem: a) -> List<a> {
  when self is {
    [] -> []
    [x, ..xs] ->
      if x == elem {
        xs
      } else {
        [x, ..delete(xs, elem)]
      }
  }
}

/// Drop the first `n` elements of a list.
///
/// ```aiken
/// list.drop([1, 2, 3], 2) == [3]
/// list.drop([], 42) == []
/// list.drop([1, 2, 3], 42) == []
/// ```
pub fn drop(self: List<a>, n: Int) -> List<a> {
  if n <= 0 {
    self
  } else {
    when self is {
      [] -> []
      [_x, ..xs] -> drop(xs, n - 1)
    }
  }
}

/// Returns the suffix of the given list after removing all elements that satisfy the predicate.
///
/// ```aiken
/// list.drop_while([1, 2, 3], fn(x) { x < 2 }) == [2, 3]
/// list.drop_while([], fn(x) { x > 2 }) == []
/// list.drop_while([1, 2, 3], fn(x) { x == 3 }) == [1, 2, 3]
/// ```
pub fn drop_while(self: List<a>, predicate: fn(a) -> Bool) -> List<a> {
  when self is {
    [] -> []
    [x, ..xs] ->
      if predicate(x) {
        drop_while(xs, predicate)
      } else {
        self
      }
  }
}

/// Produce a list of elements that satisfy a predicate.
///
/// ```aiken
/// list.filter([1, 2, 3], fn(x) { x >= 2 }) == [2, 3]
/// list.filter([], fn(x) { x > 2 }) == []
/// list.filter([1, 2, 3], fn(x) { x == 3 }) == [3]
/// ```
pub fn filter(self: List<a>, predicate: fn(a) -> Bool) -> List<a> {
  when self is {
    [] -> []
    [x, ..xs] ->
      if predicate(x) {
        [x, ..filter(xs, predicate)]
      } else {
        filter(xs, predicate)
      }
  }
}

/// Produce a list of transformed elements that satisfy a predicate.
///
/// ```aiken
/// let transform = fn(x) { if x % 2 == 0 { None } else { Some(3*x) } }
/// list.filter_map([1, 2, 3], transform) == [3, 9]
/// ```
pub fn filter_map(self: List<a>, predicate: fn(a) -> Option<b>) -> List<b> {
  when self is {
    [] -> []
    [x, ..xs] ->
      when predicate(x) is {
        None -> filter_map(xs, predicate)
        Some(y) -> [y, ..filter_map(xs, predicate)]
      }
  }
}

/// Return all elements except the last one.
///
/// ```aiken
/// list.init([]) == None
/// list.init([1, 2, 3]) == Some([1, 2])
/// ```
pub fn init(self: List<a>) -> Option<List<a>> {
  when self is {
    [] -> None
    _ -> Some(do_init(self))
  }
}

fn do_init(self: List<a>) -> List<a> {
  when self is {
    [] -> fail @"unreachable"
    [_] -> []
    [x, ..xs] -> [x, ..do_init(xs)]
  }
}

/// Returns a tuple with all elements that satisfy the predicate at first
/// element, and the rest as second element.
///
/// ```aiken
/// list.partition([1, 2, 3, 4], fn(x) { x % 2 == 0 }) == ([2, 4], [1, 3])
/// ```
pub fn partition(self: List<a>, predicate: fn(a) -> Bool) -> (List<a>, List<a>) {
  when self is {
    [] -> ([], [])
    [x, ..xs] -> {
      let (left, right) = partition(xs, predicate)
      if predicate(x) {
        ([x, ..left], right)
      } else {
        (left, [x, ..right])
      }
    }
  }
}

/// Extract a sublist from the given list using 0-based indexes. Negative
/// indexes wrap over, so `-1` refers to the last element of the list.
///
/// ```aiken
/// list.slice([1, 2, 3, 4, 5, 6], from: 2, to: 4) == [3, 4, 5]
/// list.slice([1, 2, 3, 4, 5, 6], from: -2, to: -1) == [5, 6]
/// list.slice([1, 2, 3, 4, 5, 6], from: 1, to: -1) == [2, 3, 4, 5, 6]
/// ```
pub fn slice(self: List<a>, from: Int, to: Int) -> List<a> {
  if from >= 0 {
    self
      |> drop(from)
      |> take(
          if to >= 0 {
            to - from + 1
          } else {
            length(self) + to - from + 1
          },
        )
  } else {
    let i = length(self) + from
    self
      |> drop(i)
      |> take(
          if to >= 0 {
            to - i + 1
          } else {
            to - from + 1
          },
        )
  }
}

/// Cut a list in two, such that the first list contains the given number of /
/// elements and the second list contains the rest.
///
/// Fundamentally equivalent to (but more efficient):
///
/// ```aiken
/// // span(xs, n) == (take(xs, n), drop(xs, n))
/// span([1, 2, 3, 4, 5], 3) == ([1, 2, 3], [4, 5])
/// ```
pub fn span(self: List<a>, n: Int) -> (List<a>, List<a>) {
  when self is {
    [] -> ([], [])
    [x, ..xs] ->
      if n <= 0 {
        ([], self)
      } else {
        let (left, right) = span(xs, n - 1)
        ([x, ..left], right)
      }
  }
}

/// Get elements of a list after the first one, if any.
///
/// ```aiken
/// list.tail([]) == None
/// list.tail([1, 2, 3]) == Some([2, 3])
/// ```
pub fn tail(self: List<a>) -> Option<List<a>> {
  when self is {
    [] -> None
    [_, ..xs] -> Some(xs)
  }
}

/// Get the first `n` elements of a list.
///
/// ```aiken
/// list.take([1, 2, 3], 2) == [1, 2]
/// list.take([1, 2, 3], 14) == [1, 2, 3]
/// ```
pub fn take(self: List<a>, n: Int) -> List<a> {
  if n <= 0 {
    []
  } else {
    when self is {
      [] -> []
      [x, ..xs] -> [x, ..take(xs, n - 1)]
    }
  }
}

/// Returns the longest prefix of the given list where all elements satisfy the predicate.
///
/// ```aiken
/// list.take_while([1, 2, 3], fn(x) { x > 2 }) == []
/// list.take_while([1, 2, 3], fn(x) { x < 2 }) == [1]
/// ```
pub fn take_while(self: List<a>, predicate: fn(a) -> Bool) -> List<a> {
  when self is {
    [] -> []
    [x, ..xs] ->
      if predicate(x) {
        [x, ..take_while(xs, predicate)]
      } else {
        []
      }
  }
}

/// Removes duplicate elements from a list.
///
/// ```aiken
/// list.unique([1, 2, 3, 1]) == [1, 2, 3]
/// ```
pub fn unique(self: List<a>) -> List<a> {
  when self is {
    [] -> []
    [x, ..xs] -> [x, ..unique(filter(xs, fn(y) { y != x }))]
  }
}

// ### Extracting Forcibly

/// More efficient version of [`delete`](#delete), which also fails when the element is NOT in the list.
///
/// ```aiken
/// list.expect_delete([1, 2, 3, 1], 1) == [2, 3, 1]
/// list.expect_delete([1, 2, 3], 14) → 💥
/// ```
pub fn expect_delete(self: List<a>, elem: a) -> List<a> {
  let head = builtin.head_list(self)
  if head == elem {
    builtin.tail_list(self)
  } else {
    [head, ..expect_delete(builtin.tail_list(self), elem)]
  }
}

/// More efficient version of [`drop`](#drop), which fails when there's less than `n` elements in the list.
///
/// Yields the list when `n` is negative.
pub fn expect_drop(self: List<a>, n: Int) -> List<a> {
  if n >= 2 {
    expect_drop(builtin.tail_list(builtin.tail_list(self)), n - 2)
  } else {
    if n <= 0 {
      self
    } else {
      builtin.tail_list(self)
    }
  }
}

/// More efficient version of [`init`](#init), which fails when the list is empty.
pub fn expect_init(self: List<a>) -> List<a> {
  when self is {
    [_] -> []
    _ -> [builtin.head_list(self), ..expect_init(builtin.tail_list(self))]
  }
}

/// More efficient version of [`tail`](#tail), which fails when the list is empty.
pub fn expect_tail(self: List<a>) -> List<a> {
  builtin.tail_list(self)
}

/// More efficient version of [`take`](#take), which fails when the list contains less element than wanted.
///
/// Yields an empty list when `n` is negative.
pub fn expect_take(self: List<a>, n: Int) -> List<a> {
  if n >= 2 {
    let tail = builtin.tail_list(self)
    [
      builtin.head_list(self),
      builtin.head_list(tail),
      ..expect_take(builtin.tail_list(tail), n - 2)
    ]
  } else {
    if n <= 0 {
      []
    } else {
      [builtin.head_list(self)]
    }
  }
}

// ### Mapping

/// More efficient
/// Map elements of a list into a new list and flatten the result.
///
/// ```aiken
/// list.flat_map([1, 2, 3], fn(a) { [a, 2*a] }) == [1, 2, 2, 4, 3, 6]
/// ```
pub fn flat_map(self: List<a>, with: fn(a) -> List<b>) -> List<b> {
  foldr(self, [], fn(x, xs) { concat(with(x), xs) })
}

/// Perform an action for each element of a list.
///
/// ```aiken
/// list.for_each(labels, do: fn(lbl) { trace lbl Void })
/// ```
pub fn for_each(self: List<a>, do: fn(a) -> Void) -> Void {
  foldr(self, Void, fn(x, _) { do(x) })
}

/// List [`map`](#map) but provides the position (0-based) of the elements while iterating.
///
/// ```aiken
/// list.indexed_map([1, 2, 3], fn(i, x) { i + x }) == [1, 3, 5]
/// ```
pub fn indexed_map(self: List<a>, with: fn(Int, a) -> result) -> List<result> {
  do_indexed_map(0, self, with)
}

fn do_indexed_map(
  n: Int,
  self: List<a>,
  with: fn(Int, a) -> result,
) -> List<result> {
  when self is {
    [] -> []
    [x, ..xs] -> [with(n, x), ..do_indexed_map(n + 1, xs, with)]
  }
}

/// Apply a function to each element of a list.
///
/// ```aiken
/// list.map([1, 2, 3, 4], fn(n) { n + 1 }) == [2, 3, 4, 5]
/// ```
pub fn map(self: List<a>, with: fn(a) -> result) -> List<result> {
  when self is {
    [] -> []
    [x, ..xs] -> [with(x), ..map(xs, with)]
  }
}

/// Apply a function of two arguments, combining elements from two lists.
///
/// > [!NOTE]
/// > If one list is longer, the extra elements are dropped.
///
/// ```aiken
/// list.map2([1, 2, 3], [1, 2], fn(a, b) { a + b }) == [2, 4]
/// ```
pub fn map2(
  self: List<a>,
  bs: List<b>,
  with: fn(a, b) -> result,
) -> List<result> {
  when self is {
    [] -> []
    [x, ..xs] ->
      when bs is {
        [] -> []
        [y, ..ys] -> [with(x, y), ..map2(xs, ys, with)]
      }
  }
}

/// Apply a function of three arguments, combining elements from three lists.
///
/// > [!NOTE]
/// > If one list is longer, the extra elements are dropped.
///
/// ```aiken
/// list.map3([1, 2, 3], [1, 2], [1, 2, 3], fn(a, b, c) { a + b + c }) == [3, 6]
/// ```
pub fn map3(
  self: List<a>,
  bs: List<b>,
  cs: List<c>,
  with: fn(a, b, c) -> result,
) -> List<result> {
  when self is {
    [] -> []
    [x, ..xs] ->
      when bs is {
        [] -> []
        [y, ..ys] ->
          when cs is {
            [] -> []
            [z, ..zs] -> [with(x, y, z), ..map3(xs, ys, zs, with)]
          }
      }
  }
}

/// Return the list with its elements in the reserve order.
///
/// ```aiken
/// list.reverse([1, 2, 3]) == [3, 2, 1]
/// ```
pub fn reverse(self: List<a>) -> List<a> {
  foldl(self, [], fn(x, xs) { [x, ..xs] })
}

/// Sort a list in ascending order using the given comparison function.
///
/// ```aiken
/// use aiken/primitive/int
///
/// list.sort([3, 1, 4, 0, 2], int.compare) == [0, 1, 2, 3, 4]
/// list.sort([1, 2, 3], int.compare) == [1, 2, 3]
/// ```
pub fn sort(self: List<a>, compare: fn(a, a) -> Ordering) -> List<a> {
  when self is {
    [] -> []
    [x, ..xs] -> insert(sort(xs, compare), x, compare)
  }
}

fn insert(self: List<a>, e: a, compare: fn(a, a) -> Ordering) -> List<a> {
  when self is {
    [] -> [e]
    [x, ..xs] ->
      if compare(e, x) == Less {
        [e, ..self]
      } else {
        [x, ..insert(xs, e, compare)]
      }
  }
}

/// Decompose a list of tuples into a tuple of lists.
///
/// ```
/// list.unzip([(1, "a"), (2, "b")]) == ([1, 2], ["a", "b"])
/// ```
pub fn unzip(self: List<(a, b)>) -> (List<a>, List<b>) {
  when self is {
    [] -> ([], [])
    [(a, b), ..xs] -> {
      let (a_tail, b_tail) = unzip(xs)
      ([a, ..a_tail], [b, ..b_tail])
    }
  }
}

// ## Combining

/// Merge two lists together.
///
/// ```aiken
/// list.concat([], []) == []
/// list.concat([], [1, 2, 3]) == [1, 2, 3]
/// list.concat([1, 2, 3], [4, 5, 6]) == [1, 2, 3, 4, 5, 6]
/// ```
pub fn concat(left: List<a>, right: List<a>) -> List<a> {
  when left is {
    [] -> right
    [x, ..xs] -> [x, ..concat(xs, right)]
  }
}

/// Remove the first occurrence of each element of the second list from the first one.
///
/// ```
/// list.difference(["h", "e", "l", "l", "o"], ["l", "e", "l"]) == ["h", "o"]
/// list.difference([1, 2, 3, 4, 5], [1, 1, 2]) == [3, 4, 5]
/// list.difference([1, 2, 3], []) == [1, 2, 3]
/// ```
pub fn difference(self: List<a>, with: List<a>) -> List<a> {
  when with is {
    [] -> self
    [x, ..xs] -> difference(delete(self, x), xs)
  }
}

/// Combine two lists together.
///
/// > [!NOTE]
/// > If one list is longer, the extra elements are dropped.
///
/// ```aiken
/// list.zip([1, 2], ["a", "b", "c"]) == [(1, "a"), (2, "b")]
/// ```
pub fn zip(self: List<a>, bs: List<b>) -> List<(a, b)> {
  when self is {
    [] -> []
    [x, ..xs] ->
      when bs is {
        [] -> []
        [y, ..ys] -> [(x, y), ..zip(xs, ys)]
      }
  }
}

// ## Transforming

/// Reduce a list from left to right.
///
/// ```aiken
/// list.foldl([1, 2, 3], 0, fn(n, total) { n + total }) == 6
/// list.foldl([1, 2, 3], [], fn(x, xs) { [x, ..xs] }) == [3, 2, 1]
/// ```
pub fn foldl(self: List<a>, zero: b, with: fn(a, b) -> b) -> b {
  when self is {
    [] -> zero
    [x, ..xs] -> foldl(xs, with(x, zero), with)
  }
}

/// A function callback to accumulate two returned values at once. See also [`foldl2`](#foldl2) and [`foldr2`](#foldr2) about usage.
pub type Fold2<a, b, result> =
  fn(a, b) -> result

/// Reduce a list from left to right, while accumulating two results. This is
/// faster (albeit equivalent) than accumulating both results in a `Pair` or tuple.
///
/// > [!TIP]
/// > Using [`backpassing`](https://aiken-lang.org/language-tour/functions#backpassing-) to ease readability is a good idea.
///
/// ```aiken
/// let len, sum <-
///    foldl2(
///      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
///      0,
///      0,
///      fn(n, len, sum, return) { return(len + 1, sum + n) },
///    )
///
/// and {
///   len == 10,
///   sum == 55,
/// }
/// ```
pub fn foldl2(
  self: List<elem>,
  zero_a: a,
  zero_b: b,
  with: fn(elem, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> result {
  when self is {
    [] -> return(zero_a, zero_b)
    [x, ..xs] -> {
      let a, b <- with(x, zero_a, zero_b)
      foldl2(xs, a, b, with, return)
    }
  }
}

/// Reduce a list from right to left.
///
/// ```aiken
/// list.foldr([1, 2, 3], 0, fn(n, total) { n + total }) == 6
/// list.foldr([1, 2, 3], [], fn(x, xs) { [x, ..xs] }) == [1, 2, 3]
/// ```
pub fn foldr(self: List<a>, zero: b, with: fn(a, b) -> b) -> b {
  when self is {
    [] -> zero
    [x, ..xs] -> with(x, foldr(xs, zero, with))
  }
}

/// Reduce a list from right to left, while accumulating two results. This is
/// faster (albeit equivalent) than accumulating both results in a `Pair` or tuple.
///
/// > [!TIP]
/// > Using [`backpassing`](https://aiken-lang.org/language-tour/functions#backpassing-) to ease readability is a good idea.
///
/// ```aiken
/// let len, sum <-
///    list.foldr2(
///      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
///      0,
///      0,
///      fn(n, len, sum, return) { return(len + 1, sum + n) },
///    )
///
/// and {
///   len == 10,
///   sum == 55,
/// }
/// ```
pub fn foldr2(
  self: List<elem>,
  zero_a: a,
  zero_b: b,
  with: fn(elem, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> result {
  do_foldr2(self, with, return)(zero_a, zero_b)
}

fn do_foldr2(
  self: List<elem>,
  with: fn(elem, a, b, Fold2<a, b, result>) -> result,
  return: Fold2<a, b, result>,
) -> Fold2<a, b, result> {
  when self is {
    [] -> return
    [x, ..xs] -> do_foldr2(xs, with, fn(a, b) { with(x, a, b, return) })
  }
}

/// Like [`foldr`](#foldr), but also provides the position (0-based) of the elements when iterating.
///
/// ```aiken
/// let group = fn(i, x, xs) { [(i, x), ..xs] }
/// list.indexed_foldr(["a", "b", "c"], [], group) == [
///   (0, "a"),
///   (1, "b"),
///   (2, "c")
/// ]
/// ```
pub fn indexed_foldr(
  self: List<a>,
  zero: result,
  with: fn(Int, a, result) -> result,
) -> result {
  do_indexed_foldr(0, self, zero, with)
}

fn do_indexed_foldr(
  n: Int,
  self: List<a>,
  zero: result,
  with: fn(Int, a, result) -> result,
) -> result {
  when self is {
    [] -> zero
    [x, ..xs] -> with(n, x, do_indexed_foldr(n + 1, xs, zero, with))
  }
}

/// Reduce a list from left to right using the accumulator as left operand.
/// Said differently, this is [`foldl`](#foldl) with callback arguments swapped.
///
/// ```aiken
/// list.reduce([#[1], #[2], #[3]], #[0], bytearray.concat) == #[0, 1, 2, 3]
/// list.reduce([True, False, True], False, fn(b, a) { or { b, a } }) == True
/// ```
pub fn reduce(self: List<a>, zero: b, with: fn(b, a) -> b) -> b {
  foldl(self, zero, flip(with))
}
