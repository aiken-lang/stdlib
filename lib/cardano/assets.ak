use aiken/builtin
use aiken/collection/dict.{Dict}
use aiken/collection/dict/strategy as dict_strategy
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{Blake2b_224, Hash, Script}
use cardano/assets/strategy.{FlattenStrategy}

/// `Lovelace` is a type-alias for `Int`.
pub type Lovelace =
  Int

/// A type-alias for a `PolicyId`. A `PolicyId` is always 28-byte long
pub type PolicyId =
  Hash<Blake2b_224, Script>

/// Ada, the native currency, isn't associated with any `PolicyId` (it's not
/// possible to mint Ada!).
///
/// By convention, it is an empty `ByteArray`.
pub const ada_policy_id = ""

/// A type-alias for 'AssetName`, which are free-form byte-arrays between
/// 0 and 32 bytes.
pub type AssetName =
  ByteArray

/// Ada, the native currency, isn't associated with any `AssetName` (it's not
/// possible to mint Ada!).
///
/// By convention, it is an empty `ByteArray`.
pub const ada_asset_name = ""

/// A multi-asset output `Value`. Contains tokens indexed by [PolicyId](#PolicyId) and [AssetName](#AssetName).
///
/// > [!IMPORTANT]
/// > This type maintain some invariants by construction; in particular, a `Value` will never contain a
/// zero quantity of a particular token.
pub opaque type Value {
  inner: Dict<PolicyId, Dict<AssetName, Int>>,
}

// ## Constructing

/// Construct a `Value` from an asset identifier (i.e. `PolicyId` + `AssetName`)
/// and a given quantity.
pub fn from_asset(
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> Value {
  if 0 == quantity {
    zero
  } else {
    dict.singleton(policy_id, dict.singleton(asset_name, quantity))
      |> Value
  }
}

pub fn from_ascending_pairs(xs: Pairs<PolicyId, Dict<AssetName, Int>>) -> Value {
  xs
    |> dict.from_ascending_pairs_with(
        fn(inner) {
          and {
            dict.empty != inner,
            dict.foldl(
              inner,
              True,
              fn(_, quantity, is_non_zero) { is_non_zero && 0 != quantity },
            ),
          }
        },
      )
    |> Value
}

/// Promote an arbitrary list of assets into a `Value`. This function fails
/// (i.e. halts the program execution) if:
///
/// - there's any duplicate amongst `PolicyId`;
/// - there's any duplicate amongst `AssetName`;
/// - the `AssetName` aren't sorted in ascending lexicographic order; or
/// - any asset quantity is null.
///
/// This function is meant to turn arbitrary user-defined `Data` into safe `Value`,
/// while checking for internal invariants.
pub fn from_asset_list(xs: Pairs<PolicyId, Pairs<AssetName, Int>>) -> Value {
  xs
    |> list.foldr(
        dict.empty,
        fn(Pair(policy, assets), acc) {
          when assets is {
            [] -> fail @"from_asset_list: empty assets"
            _ ->
              assets
                |> dict.from_ascending_pairs_with(fn(v) { 0 != v })
                |> dict.insert_with(
                    acc,
                    policy,
                    _,
                    dict_strategy.expect_no_duplicate(),
                  )
          }
        },
      )
    |> Value
}

/// Construct a `Value` from a lovelace quantity.
///
/// Friendly reminder: 1 Ada = 1.000.000 Lovelace
pub fn from_lovelace(quantity: Int) -> Value {
  from_asset(ada_policy_id, ada_asset_name, quantity)
}

/// Construct an empty `Value` with nothing in it.
pub const zero: Value = Value { inner: dict.empty }

// ## Inspecting

/// Check whether some tokens list is contained within another. This is a
/// specialised version of [`dict.{contains}`](../aiken/collection/dict.html#contains).
pub fn contains(
  self: Dict<AssetName, Int>,
  subset: Dict<AssetName, Int>,
) -> Bool {
  do_contains(dict.to_pairs(self), dict.to_pairs(subset))
}

fn do_contains(
  self: Pairs<AssetName, Int>,
  subset: Pairs<AssetName, Int>,
) -> Bool {
  when subset is {
    [] -> True
    [head_subset, ..tail_subset] -> {
      let head_superset, tail_superset <- pairs.pop_until_key_and_then(
        self,
        head_subset.1st,
      )
      and {
        when head_superset is {
          None -> False
          Some(head_superset) -> head_superset >= head_subset.2nd
        },
        do_contains(tail_superset, tail_subset),
      }
    }
  }
}

/// Check whether a `Value` contains any token under the given policy whose
/// quantity is exactly `1`. Other assets are tolerated.
///
/// This only speaks about uniqueness *within the given `Value`*.
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("bar", "asset#2", 14)
///
/// assets.has_any_unique(value, "foo") == True
/// assets.has_any_unique(value, "bar") == False
/// assets.has_any_unique(value, "baz") == False
/// ```
pub fn has_any_unique(self: Value, policy: PolicyId) -> Bool {
  tokens(self, policy)
    |> dict.foldr(False, fn(_, quantity, result) { result || 1 == quantity })
}

/// Backward-compatible alias for [`has_any_unique`](#has_any_unique).
///
/// This checks whether a token is unique within the given `Value`; it does not
/// prove any blockchain-wide NFT property.
pub fn has_any_nft(self: Value, policy: PolicyId) -> Bool {
  has_any_unique(self, policy)
}

/// Check whether a `Value` contains exactly one token under the given policy,
/// optionally alongside Ada.
///
/// This only speaks about uniqueness *within the given `Value`*.
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("bar", "asset#2", 14)
///
/// assets.has_any_unique_strict(value, "foo") == False
/// assets.has_any_unique_strict(value, "bar") == False
/// assets.has_any_unique_strict(value, "baz") == False
/// ```
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///
/// assets.has_any_unique_strict(value, "foo") == True
/// assets.has_any_unique_strict(value, "bar") == False
/// ```
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("foo", "asset#2", 1)
///
/// assets.has_any_unique_strict(value, "foo") == False
/// assets.has_any_unique_strict(value, "bar") == False
/// ```
pub fn has_any_unique_strict(self: Value, policy: PolicyId) -> Bool {
  let check_inner = fn(p, inner) {
    and {
      policy == p,
      when inner |> dict.to_pairs is {
        [Pair(_, 1)] -> True
        _ -> False
      },
    }
  }

  when self.inner |> dict.to_pairs is {
    [Pair(p1, _), Pair(p2, inner)] -> and {
        p1 == ada_policy_id,
        check_inner(p2, inner),
      }

    [Pair(p, inner)] -> check_inner(p, inner)

    _ -> False
  }
}

/// Backward-compatible alias for [`has_any_unique_strict`](#has_any_unique_strict).
///
/// This checks whether a token is unique within the given `Value`; it does not
/// prove any blockchain-wide NFT property.
pub fn has_any_nft_strict(self: Value, policy: PolicyId) -> Bool {
  has_any_unique_strict(self, policy)
}

/// Check whether a `Value` contains exactly one unit of a specific token. Other
/// assets are tolerated.
///
/// This only speaks about uniqueness *within the given `Value`*.
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("bar", "asset#2", 14)
///
/// assets.has_unique(value, "foo", "asset#1") == True
/// assets.has_unique(value, "foo", "asset#2") == False
/// assets.has_unique(value, "bar", "asset#2") == False
/// assets.has_unique(value, "baz", "asset#3") == False
/// ```
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("foo", "asset#2", 1)
///
/// assets.has_unique(value, "foo", "asset#1") == True
/// assets.has_unique(value, "foo", "asset#2") == True
/// assets.has_unique(value, "bar", "asset#2") == False
/// ```
pub fn has_unique(self: Value, policy: PolicyId, asset_name: AssetName) -> Bool {
  1 == quantity_of(self, policy, asset_name)
}

/// Backward-compatible alias for [`has_unique`](#has_unique).
///
/// This checks whether a token is unique within the given `Value`; it does not
/// prove any blockchain-wide NFT property.
pub fn has_nft(self: Value, policy: PolicyId, asset_name: AssetName) -> Bool {
  has_unique(self, policy, asset_name)
}

/// Check whether a `Value` contains no assets other than exactly one unit of a
/// specific token and optional Ada.
///
/// This only speaks about uniqueness *within the given `Value`*.
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("bar", "asset#2", 14)
///
/// assets.has_unique_strict(value1, "foo", "asset#1") == False
/// assets.has_unique_strict(value1, "bar", "asset#2") == False
/// assets.has_unique_strict(value1, "baz", "asset#3") == False
/// ```
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///
/// assets.has_unique_strict(value, "foo", "asset#1") == True
/// assets.has_unique_strict(value, "foo", "asset#2") == False
/// assets.has_unique_strict(value, "bar", "asset#2") == False
/// ```
///
/// ```aiken
/// let value = assets.from_lovelace(42)
///    |> assets.add("foo", "asset#1", 1)
///    |> assets.add("foo", "asset#2", 1)
///
/// assets.has_unique_strict(value3, "foo", "asset#1") == False
/// assets.has_unique_strict(value3, "foo", "asset#2") == False
/// ```
pub fn has_unique_strict(
  self: Value,
  policy: PolicyId,
  asset_name: AssetName,
) -> Bool {
  match(
    self,
    builtin.map_data(
      [
        builtin.new_pair(
          policy,
          builtin.map_data([builtin.new_pair(asset_name, 1)]),
        ),
      ],
    ),
    fn(_, _) { True },
  )
}

/// Backward-compatible alias for [`has_unique_strict`](#has_unique_strict).
///
/// This checks whether a token is unique within the given `Value`; it does not
/// prove any blockchain-wide NFT property.
pub fn has_nft_strict(
  self: Value,
  policy: PolicyId,
  asset_name: AssetName,
) -> Bool {
  has_unique_strict(self, policy, asset_name)
}

/// Check is a `Value` is zero. That is, it has no assets and holds no Ada/Lovelace.
pub fn is_zero(self: Value) -> Bool {
  zero == self
}

/// Efficiently compare two values together, allowing a custom behaviour for Ada/Lovelace.
/// The second parameter is provided as `Data`, allowing to conveniently compare serialized
/// datums or similar structurually equivalent types (such as `Pairs<PolicyId, Pairs<AssetName, Lovelace>>`).
///
/// The third argument is a callback function to assert the left and right lovelace
/// quantities. Its first argument refers to the quantity of the first argument of
/// `match`, and the second argument of the callback to the quantity of the second
/// argument of `match`. In the absence of lovelace in any value, it defaults to `0`.
///
/// ```aiken
/// const value: Value =
///   assets.from_lovelace(30)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// const datum: Data =
///   assets.from_lovelace(20)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// True == assets.match(value, datum, >=)
///
/// False == assets.match(value, datum, ==)
///
/// True == assets.match(value, datum, fn(value_lovelace, datum_lovelace) {
///   2 * datum_lovelace >= value_lovelace
/// })
///
/// False == assets.match(assets.zero, datum, fn(_, _) { True })
/// ```
pub fn match(
  left: Value,
  right: Data,
  assert_lovelace: fn(Lovelace, Lovelace) -> Bool,
) -> Bool {
  builtin.choose_data(
    right,
    False,
    expect_match(left, right, assert_lovelace),
    False,
    False,
    False,
  )
}

/// A version of [`match`](#match) which simply ignores lovelace in either operands.
///
/// ```aiken
/// const value: Value =
///   assets.from_lovelace(30)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// const datum: Data =
///   assets.from_lovelace(20)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// True == assets.match(value, datum)
///
/// False == assets.match(assets.zero, datum)
/// ```
pub fn match_assets(left: Value, right: Data) -> Bool {
  builtin.choose_data(
    right,
    False,
    expect_match_assets(left, right),
    False,
    False,
    False,
  )
}

/// A specialized version of `quantity_of` for the Ada currency.
pub fn lovelace_of(self: Value) -> Int {
  quantity_of(self, ada_policy_id, ada_asset_name)
}

/// A list of all token policies in that Value with non-zero tokens.
pub fn policies(self: Value) -> List<PolicyId> {
  dict.keys(self.inner)
}

/// Extract the quantity of a given asset.
pub fn quantity_of(
  self: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  tokens(self, policy_id)
    |> dict.get_or_else(asset_name, fn() { 0 })
}

/// Get all tokens associated with a given policy.
pub fn tokens(self: Value, policy_id: PolicyId) -> Dict<AssetName, Int> {
  self.inner
    |> dict.get_or_else(policy_id, fn() { dict.empty })
}

// # Inspecting Forcibly

/// More efficient version of [`lovelace_of`](#lovelace_of), but fails when
/// there's no lovelace quantity in the [`Value`](#Value).
///
/// > [!TIP]
/// > It's worth noting that:
/// >
/// > - There's **always** some lovelace in values from **inputs** or **outputs**.
/// > - There's **never** any lovelace in values from **mint**.
pub fn expect_lovelace_of(self: Value) -> Int {
  expect Pair("", lovelaces) = self
    |> to_dict
    |> dict.to_pairs
    |> builtin.head_list
  lovelaces
    |> dict.to_pairs
    |> builtin.head_list
    |> builtin.snd_pair
}

/// A slightly more efficient version of [`match`](#match) which fails if the
/// provided `Data` is not akin to a [`Value`](#Value).
pub fn expect_match(
  left: Value,
  right: Data,
  assert_lovelace: fn(Lovelace, Lovelace) -> Bool,
) -> Bool {
  let (left_lovelace, left_assets) = dict.pop(left.inner, ada_policy_id)
  let left_assets: Data = left_assets
  let left_lovelace = when left_lovelace is {
    Some(tokens) -> list.expect_head(dict.to_pairs(tokens)).2nd
    None -> 0
  }
  when builtin.un_map_data(right) is {
    [] -> left_assets == right && assert_lovelace(left_lovelace, 0)
    [first_asset, ..right_assets] ->
      if builtin.b_data(ada_policy_id) == first_asset.1st {
        and {
          assert_lovelace(
            left_lovelace,
            builtin.un_i_data(
              builtin.head_list(builtin.un_map_data(first_asset.2nd)).2nd,
            ),
          ),
          left_assets == builtin.map_data(right_assets),
        }
      } else {
        and {
          assert_lovelace(left_lovelace, 0),
          left_assets == right,
        }
      }
  }
}

/// A slightly more efficient version of [`match_assets`](#match_assets) which
/// fails if the provided `Data` is not akin to a [`Value`](#Value).
pub fn expect_match_assets(left: Value, right: Data) -> Bool {
  let (_, left_assets) = dict.pop(left.inner, ada_policy_id)
  when builtin.un_map_data(right) is {
    [] -> builtin.equals_data(left_assets, right)
    [first_asset, ..right_assets] ->
      builtin.equals_data(
        left_assets,
        if builtin.b_data(ada_policy_id) == first_asset.1st {
          builtin.map_data(right_assets)
        } else {
          right
        },
      )
  }
}

/// More efficient version of [`quantity_of`](#quantity_of), but fails if the
/// target policy and asset aren't present in the value.
pub fn expect_quantity_of(
  self: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  self.inner
    |> dict.expect_get(policy_id)
    |> dict.expect_get(asset_name)
}

// # Modifying

/// Negates quantities of all tokens (including Ada) in that `Value`.
///
/// ```
/// v1
///   |> assets.negate
///   |> assets.merge(v1)
///   |> assets.is_zero
/// // True
/// ```
pub fn negate(self: Value) -> Value {
  dict.map(self.inner, fn(_, a) { dict.map(a, fn(_, qty) { -qty }) })
    |> Value
}

/// Get a subset of the assets restricted to the given policies.
pub fn restricted_to(self: Value, mask: List<PolicyId>) -> Value {
  list.foldr(
    policies(self),
    zero,
    fn(policy_id, value) {
      if list.has(mask, policy_id) {
        dict.foldr(
          tokens(self, policy_id),
          value,
          fn(asset_name, quantity, value) {
            add(value, policy_id, asset_name, quantity)
          },
        )
      } else {
        value
      }
    },
  )
}

/// Get a `Value` excluding Ada.
pub fn without_lovelace(self: Value) -> Value {
  dict.delete(self.inner, ada_policy_id)
    |> Value
}

// ## Modifying Forcibly

/// Removes the first policy id from a `Value`, but fails if the `Value` is
/// empty and contains no assets whatsoever.
///
/// This is useful to strip Ada forcibly out of values that are known to
/// contain Ada (e.g. inputs or outputs).
pub fn expect_tail(self: Value) -> Value {
  self.inner |> dict.expect_tail |> Value
}

// ## Combining

/// Add a (positive or negative) quantity of a single token to a assets.
/// This is more efficient than [`merge`](#merge) for a single asset.
pub fn add(
  self: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> Value {
  if 0 == quantity {
    self
  } else {
    let helper = fn(_, left, _right, keep, discard) {
      let inner_result = dict.insert_with(
        left,
        asset_name,
        quantity,
        dict_strategy.sum_if_non_zero(),
      )

      if dict.empty == inner_result {
        discard()
      } else {
        keep(inner_result)
      }
    }

    Value(
      dict.insert_with(
        self.inner,
        policy_id,
        dict.singleton(asset_name, quantity),
        helper,
      ),
    )
  }
}

pub fn difference(left v0: Value, right v1: Value) -> Value {
  Value(
    dict.difference_with(
      v0.inner,
      v1.inner,
      fn(_, a0, a1, keep, discard) {
        let result = dict.difference_with(
          a0,
          a1,
          dict_strategy.difference_if_non_zero(),
          dict_strategy.negate(),
        )
        if dict.empty == result {
          discard()
        } else {
          keep(result)
        }
      },
      fn(_k, right, keep, _discard) {
        keep(dict.map(right, fn(_, qty) { -qty }))
      },
    ),
  )
}

/// Combine two `Value` together.
pub fn merge(left v0: Value, right v1: Value) -> Value {
  Value(
    dict.union_with(
      v0.inner,
      v1.inner,
      fn(_, a0, a1, keep, discard) {
        let result = dict.union_with(a0, a1, dict_strategy.sum_if_non_zero())
        if dict.empty == result {
          discard()
        } else {
          keep(result)
        }
      },
    ),
  )
}

// ## Transforming

/// Flatten a `Value` as list of 3-tuple `(PolicyId, AssetName, Quantity)`.
///
/// Handy to manipulate values as uniform lists.
///
/// > [!CAUTION]
/// > This function is quite expensive and really only viable in testing
/// > scenarios. If you need to traverse all elements in a `Value`, prefer
/// > [`reduce`](#reduce) or more bespoke functions for your use case.
pub fn flatten(self: Value) -> List<(PolicyId, AssetName, Int)> {
  dict.foldr(
    self.inner,
    [],
    fn(policy_id, asset_list, value) {
      dict.foldr(
        asset_list,
        value,
        fn(asset_name, quantity, xs) {
          [(policy_id, asset_name, quantity), ..xs]
        },
      )
    },
  )
}

/// Flatten a `Value` as a list of results, possibly discarding some along the way. In particular, we have:
///
/// ```aiken
/// flatten(value) == flatten_with(value, strategy.triple())
/// ```
pub fn flatten_with(self: Value, with: FlattenStrategy<result>) -> List<result> {
  dict.foldr(
    self.inner,
    [],
    fn(policy_id, asset_list, value) {
      dict.foldr(
        asset_list,
        value,
        fn(asset_name, quantity, xs) {
          with(
            policy_id,
            asset_name,
            quantity,
            fn(x) { [x, ..xs] },
            fn() { xs },
          )
        },
      )
    },
  )
}

/// Reduce a value into a single result
///
/// ```
/// assets.zero
///  |> assets.add("a", "1", 10)
///  |> assets.add("b", "2", 20)
///  |> assets.reduce(v, 0, fn(_, _, quantity, acc) { acc + quantity })
///  // 30
/// ```
pub fn reduce(
  self: Value,
  start: result,
  with: fn(PolicyId, AssetName, Int, result) -> result,
) -> result {
  dict.foldr(
    self.inner,
    start,
    fn(policy_id, asset_list, result) {
      dict.foldr(asset_list, result, with(policy_id, _, _, _))
    },
  )
}

/// Convert the value into a dictionary of dictionaries.
pub fn to_dict(self: Value) -> Dict<PolicyId, Dict<AssetName, Int>> {
  self.inner
}

/// Convert the value into an associative list of pairs.
pub fn to_pairs(self: Value) -> Pairs<PolicyId, Dict<AssetName, Int>> {
  self.inner |> dict.to_pairs
}
