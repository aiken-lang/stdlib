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

/// Token quantities indexed by asset name for a single policy.
pub type Tokens =
  Dict<AssetName, Int>

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

/// A multi-asset output `Assets`. Contains tokens indexed by [PolicyId](#PolicyId) and [AssetName](#AssetName).
///
/// > [!IMPORTANT]
/// > This type maintain some invariants by construction; in particular,
/// > `Assets` will never contain a zero quantity of a particular token.
pub opaque type Assets {
  inner: Dict<PolicyId, Tokens>,
}

/// Construct an empty `Assets` with nothing in it.
pub const zero: Assets = Assets { inner: dict.empty }

// ## Constructing

/// Construct `Assets` from an asset identifier (i.e. `PolicyId` + `AssetName`)
/// and a given quantity.
pub fn from_asset(
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> Assets {
  if 0 == quantity {
    zero
  } else {
    dict.singleton(policy_id, dict.singleton(asset_name, quantity))
      |> Assets
  }
}

/// Construct an `Assets` map from a builtin `Value`
pub fn from_value(value: Value) -> Assets {
  Assets { inner: dict.from_value(value) }
}

pub fn from_ascending_pairs(xs: Pairs<PolicyId, Dict<AssetName, Int>>) -> Assets {
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
    |> Assets
}

/// Promote an arbitrary list of assets into `Assets`. This function fails
/// (i.e. halts the program execution) if:
///
/// - there's any duplicate amongst `PolicyId`;
/// - there's any duplicate amongst `AssetName`;
/// - the `AssetName` aren't sorted in ascending lexicographic order; or
/// - any asset quantity is null.
///
/// This function is meant to turn arbitrary user-defined `Data` into safe `Assets`,
/// while checking for internal invariants.
pub fn from_asset_list(xs: Pairs<PolicyId, Pairs<AssetName, Int>>) -> Assets {
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
    |> Assets
}

/// Construct `Assets` from a lovelace quantity.
///
/// Friendly reminder: 1 Ada = 1.000.000 Lovelace
pub fn from_lovelace(quantity: Int) -> Assets {
  from_asset(ada_policy_id, ada_asset_name, quantity)
}

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

/// Check whether `Assets` carry any NFT from the given policy. Other assets are tolerated.
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("bar", "token#2", 14)
///
/// assets.has_any_nft(my_assets, "foo") == True
/// assets.has_any_nft(my_assets, "bar") == False
/// assets.has_any_nft(my_assets, "baz") == False
/// ```
pub fn has_any_nft(self: Assets, policy: PolicyId) -> Bool {
  tokens(self, policy)
    |> dict.foldr(False, fn(_, quantity, result) { result || 1 == quantity })
}

/// Check whether `Assets` carry any NFT from the given policy. Other assets (other than
/// Ada) aren't tolerated. Said differently, the check succeeds if and only if
/// the assets contain no assets other than the expected NFT or Ada.
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("bar", "token#2", 14)
///
/// assets.has_any_nft_strict(my_assets, "foo") == False
/// assets.has_any_nft_strict(my_assets, "bar") == False
/// assets.has_any_nft_strict(my_assets, "baz") == False
/// ```
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///
/// assets.has_any_nft_strict(my_assets, "foo") == True
/// assets.has_any_nft_strict(my_assets, "bar") == False
/// ```
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("foo", "token#2", 1)
///
/// assets.has_any_nft_strict(my_assets, "foo") == False
/// assets.has_any_nft_strict(my_assets, "bar") == False
/// ```
pub fn has_any_nft_strict(self: Assets, policy: PolicyId) -> Bool {
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

/// Check whether `Assets` carry a specific NFT. Other assets are tolerated.
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("bar", "token#2", 14)
///
/// assets.has_nft(my_assets, "foo", "token#1") == True
/// assets.has_nft(my_assets, "foo", "token#2") == False
/// assets.has_nft(my_assets, "bar", "token#2") == False
/// assets.has_nft(my_assets, "baz", "token#3") == False
/// ```
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("foo", "token#2", 1)
///
/// assets.has_nft(my_assets, "foo", "token#1") == True
/// assets.has_nft(my_assets, "foo", "token#2") == True
/// assets.has_nft(my_assets, "bar", "token#2") == False
/// ```
pub fn has_nft(self: Assets, policy: PolicyId, asset_name: AssetName) -> Bool {
  1 == quantity_of(self, policy, asset_name)
}

/// Check whether `Assets` carry a specific NFT. Other assets (other than
/// Ada) aren't tolerated. Said differently, the check succeeds if and only if
/// assets contain no assets other than the expected NFT or Ada.
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("bar", "token#2", 14)
///
/// assets.has_nft_strict(my_assets, "foo", "token#1") == False
/// assets.has_nft_strict(my_assets, "bar", "token#2") == False
/// assets.has_nft_strict(my_assets, "baz", "token#3") == False
/// ```
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///
/// assets.has_nft_strict(my_assets, "foo", "token#1") == True
/// assets.has_nft_strict(my_assets, "foo", "token#2") == False
/// assets.has_nft_strict(my_assets, "bar", "token#2") == False
/// ```
///
/// ```aiken
/// let my_assets = assets.from_lovelace(42)
///    |> assets.add("foo", "token#1", 1)
///    |> assets.add("foo", "token#2", 1)
///
/// assets.has_nft_strict(my_assets, "foo", "token#1") == False
/// assets.has_nft_strict(my_assets, "foo", "token#2") == False
/// ```
pub fn has_nft_strict(
  self: Assets,
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

/// Check if `Assets` have no assets and holds no Ada/Lovelace.
pub fn is_zero(self: Assets) -> Bool {
  zero == self
}

/// Efficiently compare two asset maps together, allowing a custom behaviour for Ada/Lovelace.
/// The second parameter is provided as `Data`, allowing to conveniently compare serialized
/// datums or similar structurually equivalent types (such as `Pairs<PolicyId, Pairs<AssetName, Lovelace>>`).
///
/// The third argument is a callback function to assert the left and right lovelace
/// quantities. Its first argument refers to the quantity of the first argument of
/// `match`, and the second argument of the callback to the quantity of the second
/// argument of `match`. In the absence of lovelace in any assets, it defaults to `0`.
///
/// ```aiken
/// const my_assets: Assets =
///   assets.from_lovelace(30)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// const datum: Data =
///   assets.from_lovelace(20)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// True == assets.match(my_assets, datum, >=)
///
/// False == assets.match(my_assets, datum, ==)
///
/// True == assets.match(my_assets, datum, fn(my_assets_lovelace, datum_lovelace) {
///   2 * datum_lovelace >= my_assets_lovelace
/// })
///
/// False == assets.match(assets.zero, datum, fn(_, _) { True })
/// ```
pub fn match(
  left: Assets,
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
/// const my_assets: Assets =
///   assets.from_lovelace(30)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// const datum: Data =
///   assets.from_lovelace(20)
///     |> assets.add("foo", "bar", 1)
///     |> assets.add("foo", "baz", 42)
///
/// True == assets.match(my_assets, datum)
///
/// False == assets.match(assets.zero, datum)
/// ```
pub fn match_assets(left: Assets, right: Data) -> Bool {
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
pub fn lovelace_of(self: Assets) -> Int {
  quantity_of(self, ada_policy_id, ada_asset_name)
}

/// A list of all token policies in that Assets with non-zero tokens.
pub fn policies(self: Assets) -> List<PolicyId> {
  dict.keys(self.inner)
}

/// Extract the quantity of a given asset.
pub fn quantity_of(
  self: Assets,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  tokens(self, policy_id)
    |> dict.get_or_else(asset_name, fn() { 0 })
}

/// Get all tokens associated with a given policy.
pub fn tokens(self: Assets, policy_id: PolicyId) -> Dict<AssetName, Int> {
  self.inner
    |> dict.get_or_else(policy_id, fn() { dict.empty })
}

// # Inspecting Forcibly

/// More efficient version of [`lovelace_of`](#lovelace_of), but fails when
/// there's no lovelace quantity in the [`Assets`](#Assets).
///
/// > [!TIP]
/// > It's worth noting that:
/// >
/// > - There's **always** some lovelace in assets from **inputs** or **outputs**.
/// > - There's **never** any lovelace in assets from **mint**.
pub fn expect_lovelace_of(self: Assets) -> Int {
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
/// provided `Data` is not akin to a [`Assets`](#Assets).
pub fn expect_match(
  left: Assets,
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
/// fails if the provided `Data` is not akin to a [`Assets`](#Assets).
pub fn expect_match_assets(left: Assets, right: Data) -> Bool {
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
/// target policy and asset aren't present in the assets.
pub fn expect_quantity_of(
  self: Assets,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  self.inner
    |> dict.expect_get(policy_id)
    |> dict.expect_get(asset_name)
}

// # Modifying

/// Negates quantities of all tokens (including Ada) in that `Assets`.
///
/// ```
/// v1
///   |> assets.negate
///   |> assets.merge(v1)
///   |> assets.is_zero
/// // True
/// ```
pub fn negate(self: Assets) -> Assets {
  dict.map(self.inner, fn(_, a) { dict.map(a, fn(_, qty) { -qty }) })
    |> Assets
}

/// Get a subset of the assets restricted to the given policies.
pub fn restricted_to(self: Assets, mask: List<PolicyId>) -> Assets {
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

/// Get `Assets` excluding Ada.
pub fn without_lovelace(self: Assets) -> Assets {
  dict.delete(self.inner, ada_policy_id)
    |> Assets
}

// ## Modifying Forcibly

/// Removes the first policy id from an `Assets` map, but fails if the `Assets`
/// are empty and contains no assets whatsoever.
///
/// This is useful to strip Ada forcibly out of assets that are known to
/// contain Ada (e.g. inputs or outputs).
pub fn expect_tail(self: Assets) -> Assets {
  self.inner |> dict.expect_tail |> Assets
}

// ## Combining

/// Add a (positive or negative) quantity of a single token to a assets.
/// This is more efficient than [`merge`](#merge) for a single asset.
pub fn add(
  self: Assets,
  policy_id: PolicyId,
  asset_name: AssetName,
  quantity: Int,
) -> Assets {
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

    Assets(
      dict.insert_with(
        self.inner,
        policy_id,
        dict.singleton(asset_name, quantity),
        helper,
      ),
    )
  }
}

pub fn difference(left v0: Assets, right v1: Assets) -> Assets {
  Assets(
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

/// Combine two `Assets` together.
pub fn merge(left v0: Assets, right v1: Assets) -> Assets {
  Assets(
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

/// Flatten `Assets` into a list of 3-tuple `(PolicyId, AssetName, Quantity)`.
///
/// Handy to manipulate assets as uniform lists.
///
/// > [!CAUTION]
/// > This function is quite expensive and really only viable in testing
/// > scenarios. If you need to traverse all elements in an `Assets` map, prefer
/// > [`reduce`](#reduce) or more bespoke functions for your use case.
pub fn flatten(self: Assets) -> List<(PolicyId, AssetName, Int)> {
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

/// Flatten `Assets` into a list of results, possibly discarding some along the
/// way. In particular, we have:
///
/// ```aiken
/// assets.flatten(my_assets) == assets.flatten_with(my_assets, strategy.triple())
/// ```
pub fn flatten_with(self: Assets, with: FlattenStrategy<result>) -> List<result> {
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

/// Reduce assets into a single result
///
/// ```
/// assets.zero
///  |> assets.add("a", "1", 10)
///  |> assets.add("b", "2", 20)
///  |> assets.reduce(v, 0, fn(_, _, quantity, acc) { acc + quantity })
///  // 30
/// ```
pub fn reduce(
  self: Assets,
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

/// Convert assets into a dictionary of tokens.
pub fn to_dict(self: Assets) -> Dict<PolicyId, Tokens> {
  self.inner
}

/// Convert assets into pairs of tokens.
pub fn to_pairs(self: Assets) -> Pairs<PolicyId, Tokens> {
  self.inner |> dict.to_pairs
}

/// Convert assets into a builtin `Value`
///
/// [!IMPORTANT]
/// This function is rather expensive and performs a full Data-object conversion. Use with care.
pub fn to_value(self: Assets) -> Value {
  builtin.un_value_data(self.inner)
}
