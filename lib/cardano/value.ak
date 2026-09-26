//// A module for working with native builtin `Value`.
////
//// Native values keep policy ids and asset names in canonical order, omit
//// zero quantities and empty token maps, and bound quantities to signed
//// 128-bit integers. They enable specialized builtins for common operations
//// without first converting to `Data`.

use aiken/builtin
use aiken/collection/list
use cardano/assets.{AssetName, Assets, PolicyId}

/// A zero `Value` with no assets whatsoever.
pub const zero: Value = {}

// ## Constructing

/// Convert an existing [`Assets`](./assets.html#Assets) to a built-in `Value`.
///
/// ```aiken
/// use cardano/assets
/// use aiken/primitive/bytearray
///
/// const max_quantity = math.pow2(127) - 1
/// const min_quantity = -math.pow2(127)
///
/// value.from_assets(assets.from_lovelace(42)) == { lovelace: 42 }
/// value.from_assets(assets.from_lovelace(max_quantity) == { lovelace: max_quantity }
/// value.from_assets(assets.from_lovelace(max_quantity + 1)) → 💥
/// value.from_assets(assets.from_lovelace(min_quantity)) == { lovelace: min_quantity }
/// value.from_assets(assets.from_lovelace(min_quantity - 1)) → 💥
/// value.from_assets(assets.from_asset("", bytearray.replicate(33, 0))) → 💥
/// ```
///
/// > [!CAUTION]
/// > This function fails if any policy id or asset name is longer than 32
/// > bytes, or if any quantity falls outside of the interval $[-2^{127},2^{127}-1]$.
pub fn from_assets(assets: Assets) -> Value {
  builtin.un_value_data(assets)
}

/// Convert arbitrary `Data` into a `Value`. Returns `None` when the shape isn't
/// a map of byte-array policy ids to maps of byte-array asset names and integer
/// quantities.
///
/// ```aiken
/// const max_quantity = math.pow2(127) - 1
/// const my_policy = "0000000000000000000000000000"
///
/// value.from_data([Pair("", [Pair("", 42)])]) == Some({ lovelace: 42 })
/// value.from_data([Pair(my_policy, [Pair("foo", 1)])]) == Some({ my_policy: { "foo": 1 } })
/// value.from_data(42) == None
/// value.from_data([Pair("", [Pair("", max_quantity + 1)])]) → 💥
/// value.from_data([Pair(my_policy, [Pair("foo", 1), Pair("bar", 1)])]) → 💥
/// value.from_data([Pair(my_policy, [Pair("foo", 1), Pair("foo", 1)])]) → 💥
/// ```
///
/// > [!CAUTION]
/// > A correctly shaped value still fails if it has unsorted or duplicate
/// > keys, empty token maps, zero quantities, keys longer than 32 bytes, or
/// > quantities outside of the interval $[-2^{127},2^{127}-1]$.
pub fn from_data(assets: Data) -> Option<Value> {
  if assets is Pairs<PolicyId, Pairs<AssetName, Int>> {
    Some(builtin.un_value_data(assets))
  } else {
    None
  }
}

// ## Constructing Forcibly

/// Like [`from_data`](#from_data), but without checking the shape first.
///
/// ```aiken
/// value.expect_from_data([Pair("", [Pair("", 42)])]) == { lovelace: 42 }
/// value.expect_from_data(42) → 💥
/// // All other failing cases from `from_data` still apply.
/// ```
///
/// > [!CAUTION]
/// > This function fails for malformed or non-canonical data. In particular,
/// > keys must be strictly sorted and no token map or quantity may be empty or
/// > zero. Keys are limited to 32 bytes and quantities to signed 128-bit
/// > integers.
pub fn expect_from_data(assets: Data) -> Value {
  builtin.un_value_data(assets)
}

// ## Inspecting

/// Check whether every asset in `other` is present in `self` with at least the
/// same quantity.
///
/// ```aiken
/// let policy_a = #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
/// let policy_b = #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
///
/// value.contains({ policy_a: { "token": 42 } }, { policy_a: { "token": 14 } }) == True
///
/// value.contains({ policy_a: { "token": 42 } }, { policy_a: { "token": 43 } }) == False
///
/// value.contains(
///   { policy_a: { "token": 42 } },
///   { policy_a: { "token": 14 }, policy_b: { "token": 1 } },
/// ) == False
///
/// value.contains({ policy_a: { "token": -1 } }, {}) → 💥
/// ```
///
/// > [!CAUTION]
/// > This function fails if either value contains a negative quantity.
pub fn contains(self: Value, other: Value) -> Bool {
  builtin.contains_value(self, other)
}

/// Check whether a `Value` contains no assets.
///
/// ```aiken
/// value.is_zero({}) == True
/// value.is_zero({ lovelace: 42 }) == False
/// value.is_zero({ #"00000000000000000000000000000000000000000000000000000000": { "foo": 1 } }) == False
/// ```
pub fn is_zero(self: Value) -> Bool {
  zero == self
}

/// Get the lovelace quantity, or zero when the `Value` contains no lovelace.
///
/// ```aiken
/// value.lovelace_of({ lovelace: 42 }) == 42
/// value.lovelace_of({ #"00000000000000000000000000000000000000000000000000000000": { "foo": 1 } }) == 0
/// value.lovelace_of({}) == 0
/// ```
pub fn lovelace_of(self: Value) -> Int {
  quantity_of(self, "", "")
}

/// List all policy ids in ascending lexicographic order.
///
/// ```aiken
/// value.policies({
///   #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 1 },
///   #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { #"abcd": 2 },
/// }) == [
///   #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
///   #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
/// ]
///
/// value.policies({ lovelace: 42 }) == [ada_policy_id]
/// ```
///
/// > [!IMPORTANT]
/// > This function is expensive and converts the entire `Value` to `Data`. It
/// > is more expensive than direct inspection functions and fails for values
/// > with more than ~40,000 assets.
pub fn policies(self: Value) -> List<PolicyId> {
  expect assets: Pairs<PolicyId, Data> = to_data(self)
  list.map(assets, builtin.fst_pair)
}

/// Get the quantity of an asset, or zero when the asset isn't present.
///
/// ```aiken
/// value.quantity_of(value.insert({}, "a", "token", 42), "a", "token") == 42
/// value.quantity_of(value.insert({}, "a", "token", 42), "b", "token") == 0
/// value.quantity_of({}, "a", "token") == 0
/// ```
pub fn quantity_of(
  self: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  builtin.lookup_value(policy_id, asset_name, self)
}

// ## Modifying

/// Remove an asset. If the asset isn't present, the `Value` is unchanged.
///
/// ```aiken
/// let my_value = value.insert({}, "a", "token", 42)
/// value.delete(my_value, "a", "token") == {}
/// value.delete(my_value, "b", "token") == my_value
/// value.delete(my_value, "a", "not_my_token") == my_value
/// value.delete({}, "a", "token") == {}
/// ```
pub fn delete(self: Value, policy_id: PolicyId, asset_name: AssetName) -> Value {
  builtin.insert_value(policy_id, asset_name, 0, self)
}

/// Insert an asset quantity, replacing any existing quantity for the same
/// policy id and asset name. A zero quantity removes the asset instead.
///
/// ```aiken
/// let my_value = value.insert({}, "a", "token", 42)
/// value.quantity_of(my_value, "a", "token") == 42
/// value.quantity_of(my_value, "b", "token") == 0
/// value.quantity_of(my_value, "a", "not_my_token") == 0
/// (my_value |> value.insert("a", "token", 14) |> value.quantity_of("a", "token")) == 14
/// ```
///
/// > [!IMPORTANT]
/// > Unlike [`assets.add`](./assets.html#add), this function replaces an
/// > existing quantity instead of adding to it. Use [`merge`](#merge) to add
/// > quantities from two values.
///
/// > [!CAUTION]
/// > This function fails when inserting a key longer than 32 bytes or a
/// > quantity outside of the interval $[-2^{127},2^{127}-1]$.
pub fn insert(
  self: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> Value {
  builtin.insert_value(policy_id, asset_name, quantity, self)
}

/// Negate every asset quantities.
///
/// ```aiken
/// const min_quantity = -math.pow2(127)
///
/// value.negate({ lovelace: 42 }) == { lovelace: -42 }
/// value.negate({ lovelace: -42 }) == { lovelace: 42 }
/// value.negate({ lovelace: min_quantity }) → 💥
/// ```
///
/// > [!CAUTION]
/// > This function fails when negating the minimum signed 128-bit quantity.
pub fn negate(self: Value) -> Value {
  scale(self, -1)
}

/// Keep only assets whose policy id occurs in `mask`.
///
/// ```aiken
/// let my_value = {
///   #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 1 },
///   #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "y": 1 },
/// }
///
/// value.restricted_to(my_value, [#"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"]) == {
///   #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "y": 1 },
/// }
///
/// value.restricted_to(my_value, []) == {}
///
/// value.restricted_to(my_value, [#"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc"]) == {}
/// ```
///
/// > [!IMPORTANT]
/// > This function is expensive, for it traverses and rebuilds the entire
/// > `Value`. It fails for values with more than ~40,000 assets.
pub fn restricted_to(self: Value, mask: List<PolicyId>) -> Value {
  reduce(
    self,
    zero,
    fn(policy_id, asset_name, quantity, result) {
      if list.has(mask, policy_id) {
        insert(result, policy_id, asset_name, quantity)
      } else {
        result
      }
    },
  )
}

/// Multiply every asset quantity by `factor`. A zero factor produces an empty
/// `Value`.
///
/// ```aiken
/// value.scale({ lovelace: 14 }, 2) == { lovelace: 28 }
/// value.scale({ lovelace: 14 }, 0) == {}
/// value.scale(any_value, -1) == value.negate(any_value)
/// ```
///
/// > [!CAUTION]
/// > This function fails if a resulting quantity falls outside the signed
/// > 128-bit range.
pub fn scale(self: Value, factor: Int) -> Value {
  builtin.scale_value(factor, self)
}

/// Remove lovelace while preserving all native assets.
///
/// ```aiken
/// value.without_lovelace({ lovlace: 14 }) == {}
/// value.without_lovelace({}) == {}
/// value.lovelace_of(value.without_lovelace(any_value)) == 0
/// ```
pub fn without_lovelace(self: Value) -> Value {
  delete(self, "", "")
}

// ## Combining

/// Subtract all quantities in `right` from their counterparts in `left`.
/// Assets present only in `right` are included with negative quantities.
///
/// ```aiken
/// value.difference(
///   {
///     #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 42, "y": 14 },
///     #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "x": 42 },
///     #"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc": { "x": 1 },
///   },
///   {
///     #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 14 },
///     #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "x": 42 },
///   },
/// ) == {
///   #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 28 } },
///   #"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc": { "x": 1 } },
/// }
/// ```
///
/// > [!CAUTION]
/// > This function fails if negation or subtraction produces a quantity
/// > outside of the interval $[-2^{127},2^{127}-1]$.
pub fn difference(left: Value, right: Value) -> Value {
  builtin.union_value(left, builtin.scale_value(-1, right))
}

/// Add corresponding quantities from two values, removing assets whose sum is
/// zero.
///
/// ```aiken
/// value.merge(
///   {
///     #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 42, "y": 14 },
///     #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "x": 42 },
///     #"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc": { "x": 1 },
///   },
///   {
///     #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 14 },
///     #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "x": 42 },
///   },
/// ) == {
///   #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": { "x": 56, "y": 14 },
///   #"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { "x": 84 },
///   #"cccccccccccccccccccccccccccccccccccccccccccccccccccccccc": { "x": 1 },
/// }
/// ```
///
/// > [!CAUTION]
/// > This function fails if a sum falls outside of the interval $[-2^{127},2^{127}-1]$.
pub fn merge(left: Value, right: Value) -> Value {
  builtin.union_value(left, right)
}

// ## Transforming

/// Reduce all assets from right to left and in ascending policy-id and
/// asset-name order.
///
/// ```aiken
/// let assets = {} |> value.insert("a", "x", 14) |> value.insert("b", "y", 28)
/// value.reduce(assets, 0, fn(_, _, quantity, total) { quantity + total }) == 42
/// ```
///
/// > [!IMPORTANT]
/// > This function converts the entire `Value` to `Data` before traversing it,
/// > and fails for values with more than ~40,000 assets.
pub fn reduce(
  self: Value,
  start: result,
  with: fn(PolicyId, AssetName, Int, result) -> result,
) -> result {
  list.foldr(
    to_pairs(self),
    start,
    fn(Pair(policy_id, tokens), result) {
      list.foldr(
        tokens,
        result,
        fn(Pair(asset_name, quantity), result) {
          with(policy_id, asset_name, quantity, result)
        },
      )
    },
  )
}

/// Convert a `Value` to its map-shaped `Data` representation.
///
/// ```aiken
/// value.to_data({ lovelace: 42 }) == [Pair(#"", [Pair(#"", 42)])]
/// ```
///
/// > [!CAUTION]
/// > This function fails for values with more than ~40,000 assets.
pub fn to_data(self: Value) -> Data {
  builtin.value_data(self)
}

/// Convert a `Value` to policy-token pairs in ascending lexicographic order.
///
/// ```aiken
/// use aiken/collection/dict
///
/// value.to_pairs(value.insert({}, "a", "token", 42)) == [Pair("a", Pair("token", 42))]
/// ```
///
/// > [!IMPORTANT]
/// > This function converts the entire `Value` to `Data`. It is relatively
/// > expensive and fails for values with more than ~40,000 assets.
pub fn to_pairs(self: Value) -> Pairs<PolicyId, Pairs<AssetName, Int>> {
  expect assets: Pairs<PolicyId, Pairs<AssetName, Int>> = to_data(self)
  assets
}
