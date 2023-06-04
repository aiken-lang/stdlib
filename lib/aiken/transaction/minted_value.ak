use aiken/bytearray
use aiken/dict.{Dict}
use aiken/list
use aiken/option
use aiken/transaction/value.{
  AssetName, PolicyId, Value, ada_asset_name, ada_policy_id,
}

/// A multi-asset value that can be found when minting transaction. Note that
/// because of historical reasons, this is slightly different from `Value` found
/// in transaction outputs.
///
/// Note that you're never expected to construct a `MintedValue` yourself. If you need to
/// manipulate multi-asset values, use [Value](/value.html#Value)
///
/// See also [`to_value`](#to_value).
pub opaque type MintedValue {
  inner: Dict<PolicyId, Dict<AssetName, Int>>,
}

/// Convert a 'MintedValue' into a 'Value'.
pub fn to_value(self: MintedValue) -> Value {
  foldr(
    self,
    value.zero(),
    fn(policy_id, asset_name, quantity, st) {
      value.add(st, policy_id, asset_name, quantity)
    },
  )
}

test to_value_1() {
  value.flatten(to_value(from_list([]))) == []
}

test to_value_2() {
  value.flatten(to_value(from_list([("p0", "a0", 1)]))) == [("p0", "a0", 1)]
}

test to_value_3() {
  let assets =
    [("p0", "a0", 1), ("p1", "a0", 1), ("p0", "a0", 1), ("p1", "a1", 1)]

  let result =
    [("p0", "a0", 2), ("p1", "a0", 1), ("p1", "a1", 1)]

  value.flatten(to_value(from_list(assets))) == result
}

test to_value_4() {
  let assets =
    [("p0", "a0", 1), ("p0", "a0", -1)]

  value.flatten(to_value(from_list(assets))) == []
}

test to_value_5() {
  let assets =
    [
      ("p0", "a0", 1),
      ("p0", "a1", 1),
      ("p1", "a0", 1),
      ("p1", "a1", 1),
      ("p1", "a2", 1),
      ("p2", "a0", 1),
      ("p2", "a1", 1),
      ("p3", "a0", 1),
      ("p3", "a1", 1),
      ("p3", "a2", 1),
      ("p3", "a3", 1),
      ("p3", "a4", 1),
      ("p3", "a5", 1),
      ("p3", "a6", 1),
      ("p3", "a7", 1),
    ]

  value.flatten(to_value(from_list(assets))) == assets
}

/// Extract the quantity of a given asset.
pub fn quantity_of(
  self: MintedValue,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  self.inner
    |> dict.get(policy_id)
    |> option.and_then(dict.get(_, asset_name))
    |> option.or_else(0)
}

/// A specialized version of `quantity_of` for the Ada currency.
pub fn lovelace_of(self: MintedValue) -> Int {
  quantity_of(self, ada_policy_id, ada_asset_name)
}

/// Get all tokens associated with a given policy.
pub fn tokens(self: MintedValue, policy_id: PolicyId) -> Dict<AssetName, Int> {
  self.inner
    |> dict.get(policy_id)
    |> option.or_else(dict.new())
}

/// A list of all token policies in that MintedValue with non-zero tokens.
pub fn policies(self: MintedValue) -> List<PolicyId> {
  dict.keys(self.inner)
}

/// Flatten a minted-value as list of 3-tuple (PolicyId, AssetName, Quantity).
///
/// Handy to manipulate values as uniform lists.
pub fn flatten(self: MintedValue) -> List<(PolicyId, AssetName, Int)> {
  flatten_with(
    self,
    fn(policy_id, asset_name, quantity) {
      if quantity == 0 {
        None
      } else {
        Some((policy_id, asset_name, quantity))
      }
    },
  )
}

test flatten_1() {
  flatten(from_list([])) == []
}

test flatten_2() {
  flatten(from_list([("p0", "a0", 1)])) == [("p0", "a0", 1)]
}

test flatten_3() {
  let assets =
    [("p0", "a0", 1), ("p1", "a0", 1), ("p0", "a0", 1), ("p1", "a1", 1)]

  let result =
    [("p0", "a0", 2), ("p1", "a0", 1), ("p1", "a1", 1)]

  flatten(from_list(assets)) == result
}

test flatten_4() {
  let assets =
    [("p0", "a0", 1), ("p0", "a0", -1)]

  flatten(from_list(assets)) == []
}

/// Flatten a value as a list of results, possibly discarding some along the way.
///
/// When the transform function returns `None`, the result is discarded altogether.
pub fn flatten_with(
  self: MintedValue,
  with: fn(PolicyId, AssetName, Int) -> Option<result>,
) -> List<result> {
  dict.foldr(
    self.inner,
    [],
    fn(policy_id, asset_list, value) {
      dict.foldr(
        asset_list,
        value,
        fn(asset_name, quantity, xs) {
          when with(policy_id, asset_name, quantity) is {
            None -> xs
            Some(x) ->
              [x, ..xs]
          }
        },
      )
    },
  )
}

/// Left-fold over the assets, in ascending key order.
pub fn foldl(
  self: MintedValue,
  zero: result,
  with: fn(PolicyId, AssetName, Int, result) -> result,
) -> result {
  dict.foldl(
    self.inner,
    zero,
    fn(policy, xs, acc) {
      dict.foldl(
        xs,
        acc,
        fn(asset, quantity, result) {
          if quantity != 0 {
            with(policy, asset, quantity, result)
          } else {
            result
          }
        },
      )
    },
  )
}

test foldl_1() {
  let mv = dict.new() |> MintedValue
  foldl(mv, 0, fn(_k, _v, q, r) { q + r }) == 0
}

test foldl_2() {
  foldl(
    fold_fixture(),
    "",
    fn(_k, v, q, str) {
      if q > 1 {
        bytearray.concat(str, v)
      } else {
        str
      }
    },
  ) == "bcd"
}

/// right-fold over the assets, in ascending key order.
pub fn foldr(
  self: MintedValue,
  zero: result,
  with: fn(PolicyId, AssetName, Int, result) -> result,
) -> result {
  dict.foldr(
    self.inner,
    zero,
    fn(policy, xs, acc) {
      dict.foldr(
        xs,
        acc,
        fn(asset, quantity, result) {
          if quantity != 0 {
            with(policy, asset, quantity, result)
          } else {
            result
          }
        },
      )
    },
  )
}

test foldr_1() {
  let mv = dict.new() |> MintedValue
  foldr(mv, 0, fn(_k, _v, q, r) { q + r }) == 0
}

test foldr_2() {
  foldr(
    fold_fixture(),
    "",
    fn(_k, v, q, str) {
      if q > 1 {
        bytearray.concat(str, v)
      } else {
        str
      }
    },
  ) == "dcb"
}

fn fold_fixture() {
  dict.from_list(
    [
      ("p0", dict.from_list([("a", 1), ("b", 2), ("c", 3)], bytearray.compare)),
      ("p1", dict.from_list([("d", 3)], bytearray.compare)),
    ],
    bytearray.compare,
  )
    |> MintedValue
}

/// Convert a list of tokens into a `MintedValue`.
///
/// NOTE: Not exposed because we do not want people to construct `MintedValue`. Only
/// get them from the script context.
fn from_list(xs: List<(PolicyId, AssetName, Int)>) -> MintedValue {
  list.foldr(
    xs,
    MintedValue(dict.new()),
    fn(elem, st) {
      let (policy_id, asset_name, quantity) = elem
      add(st, policy_id, asset_name, quantity)
    },
  )
}

fn add(
  self: MintedValue,
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> MintedValue {
  MintedValue(
    dict.insert_with(
      self.inner,
      policy_id,
      dict.from_ascending_list([(asset_name, quantity)], bytearray.compare),
      fn(_, left, _right) {
        Some(
          dict.insert_with(
            left,
            asset_name,
            quantity,
            fn(_k, ql, qr) { Some(ql + qr) },
            bytearray.compare,
          ),
        )
      },
      bytearray.compare,
    ),
  )
}
