use aiken/bytearray
use aiken/dict.{Dict}
use aiken/hash.{Blake2b_224, Hash}
use aiken/option
use aiken/transaction/credential.{Script}

/// A type-alias for a `PolicyId`. A `PolicyId` is always 28-byte long
pub type PolicyId =
  Hash<Blake2b_224, Script>

/// Ada, the native currency, isn't associated with any `PolicyId` (it's not
/// possible to mint Ada!).
///
/// By convention, it is an empty `ByteArray`.
pub const ada_policy_id = #""

/// A type-alias for 'AssetName`, which are free-form byte-arrays between
/// 0 and 32 bytes.
pub type AssetName =
  ByteArray

/// Ada, the native currency, isn't associated with any `AssetName` (it's not
/// possible to mint Ada!).
///
/// By convention, it is an empty `ByteArray`.
pub const ada_asset_name = #""

/// A multi-asset output `Value`. Contains tokens indexed by [PolicyId](#PolicyId) and [AssetName](#AssetName).
///
/// This type maintain some invariants by construction; in particular, a `Value` will never contain a
/// zero quantity of a particular token.
pub opaque type Value {
  inner: Dict<PolicyId, Dict<AssetName, Int>>,
}

/// Construct an empty `Value` with nothing in it.
pub fn zero() -> Value {
  Value { inner: dict.new() }
}

/// Construct a `Value` from an asset identifier (i.e. `PolicyId` + `AssetName`)
/// and a given quantity.
pub fn from_asset(
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> Value {
  if quantity == 0 {
    dict.new()
      |> Value
  } else {
    let asset =
      dict.new()
        |> dict.insert(asset_name, quantity, bytearray.compare)
    dict.new()
      |> dict.insert(policy_id, asset, bytearray.compare)
      |> Value
  }
}

/// Construct a `Value` from a lovelace quantity.
///
/// Friendly reminder: 1 Ada = 1.000.000 Lovelace
pub fn from_lovelace(quantity: Int) -> Value {
  from_asset(ada_policy_id, ada_asset_name, quantity)
}

/// Get a `Value` excluding Ada.
pub fn without_lovelace(self: Value) -> Value {
  dict.delete(self.inner, ada_policy_id)
    |> Value
}

test without_lovelace_1() {
  let v = from_lovelace(1000000)
  without_lovelace(v) == zero()
}

test without_lovelace_2() {
  let v = from_lovelace(1000000)
  let v2 = from_lovelace(50000000)
  without_lovelace(v) == without_lovelace(v2)
}

test without_lovelace_3() {
  let v =
    from_asset(#"010203", #"040506", 100)
      |> add(from_lovelace(100000000))
  let v2 = from_asset(#"010203", #"040506", 100)
  without_lovelace(v) == without_lovelace(v2) && without_lovelace(v) == v2
}

/// Negates quantities of all tokens (including Ada) in that `Value`.
///
/// ```
/// v1
///   |> value.negate
///   |> value.add
///   |> value.is_zero
/// // True
/// ```
pub fn negate(self: Value) -> Value {
  dict.map(self.inner, fn(_, a) { dict.map(a, fn(_, q) { 0 - q }) })
    |> Value
}

/// Combine two `Value` together.
pub fn add(left v0: Value, right v1: Value) -> Value {
  dict.union_with(
    v0.inner,
    v1.inner,
    fn(_, a0, a1) {
      let result =
        dict.union_with(
          a0,
          a1,
          fn(_, q0, q1) {
            let q = q0 + q1
            if q == 0 {
              None
            } else {
              Some(q)
            }
          },
          bytearray.compare,
        )

      if dict.is_empty(result) {
        None
      } else {
        Some(result)
      }
    },
    bytearray.compare,
  )
    |> Value
}

test add_1() {
  let v1 = from_lovelace(1)
  let v2 = from_lovelace(-1)
  add(v1, v2) == zero()
}

test add_2() {
  let v1 = from_asset(#"00", #"", 1)
  let v2 = from_asset(#"01", #"", 2)
  let v3 = from_asset(#"02", #"", 3)
  let v =
    from_lovelace(42)
      |> add(v3)
      |> add(v1)
      |> add(v2)

  flatten(v) == [
    (#"", #"", 42),
    (#"00", #"", 1),
    (#"01", #"", 2),
    (#"02", #"", 3),
  ]
}

test add_3() {
  let v1 = from_asset(#"00", #"", 1)
  let v2 = from_asset(#"00", #"", -1)
  let v3 = from_asset(#"01", #"", 1)

  let v =
    zero()
      |> add(v1)
      |> add(v2)
      |> add(v3)

  flatten(v) == [(#"01", #"", 1)]
}

/// Flatten a value as list of 3-tuple (PolicyId, AssetName, Quantity).
///
/// Handy to manipulate values as uniform lists.
pub fn flatten(self: Value) -> List<(PolicyId, AssetName, Int)> {
  dict.fold(
    self.inner,
    [],
    fn(policy_id, asset, assets) {
      dict.fold(
        asset,
        assets,
        fn(asset_name, quantity, xs) {
          if quantity == 0 {
            xs
          } else {
            [(policy_id, asset_name, quantity), ..xs]
          }
        },
      )
    },
  )
}

/// Extract the quantity of a given asset.
pub fn quantity_of(
  self: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  self.inner
    |> dict.get(policy_id)
    |> option.and_then(dict.get(_, asset_name))
    |> option.or_else(0)
}

/// A specialized version of `quantity_of` for the Ada currency.
pub fn lovelace_of(self: Value) -> Int {
  quantity_of(self, ada_policy_id, ada_asset_name)
}

/// Get all tokens associated with a given policy.
pub fn tokens(self: Value, policy_id: PolicyId) -> Dict<AssetName, Int> {
  self.inner
    |> dict.get(policy_id)
    |> option.or_else(dict.new())
}

/// A list of all token policies in that Value with non-zero tokens.
pub fn policies(self: Value) -> List<PolicyId> {
  dict.keys(self.inner)
}

/// Flatten a value as a list of results, possibly discarding some along the way.
///
/// When the `transform` function returns `None`, the result is discarded altogether.
pub fn flatten_with(
  self: Value,
  transform: fn(PolicyId, AssetName, Int) -> Option<result>,
) -> List<result> {
  dict.fold(
    self.inner,
    [],
    fn(policy_id, asset, assets) {
      dict.fold(
        asset,
        assets,
        fn(asset_name, quantity, xs) {
          when transform(policy_id, asset_name, quantity) is {
            None -> xs
            Some(x) ->
              [x, ..xs]
          }
        },
      )
    },
  )
}

test flatten_with_1() {
  flatten_with(zero(), fn(p, a, q) { Some((p, a, q)) }) == []
}

test flatten_with_2() {
  let v =
    zero()
      |> add(from_asset("a", "1", 14))
      |> add(from_asset("b", "", 42))
      |> add(from_asset("a", "2", 42))

  flatten_with(
    v,
    fn(p, a, q) {
      if q == 42 {
        Some((p, a))
      } else {
        None
      }
    },
  ) == [("a", "2"), ("b", "")]
}
