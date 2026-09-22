use aiken/builtin
use aiken/collection/list
use aiken/fuzz
use aiken/primitive/bytearray
use cardano/assets.{AssetName, Assets, PolicyId, ada_asset_name, ada_policy_id}
use cardano/fuzz as cardano
use cardano/value.{
  contains, delete, difference, expect_from_data, from_assets, from_data, insert,
  is_zero, lovelace_of, merge, negate, policies, quantity_of, reduce,
  restricted_to, scale, to_data, to_pairs, without_lovelace, zero,
}

// -------------------------------------------------------------------- fixtures

const policy_a: PolicyId =
  #"00000000000000000000000000000000000000000000000000000000"

const policy_b: PolicyId =
  #"11111111111111111111111111111111111111111111111111111111"

const fixture_value: Value = {
  lovelace: 42,
  policy_a: {
    "x": 10,
    "y": -2,
  },
  policy_b: {
    "z": 7,
  },
}

const fixture_assets: Assets =
  assets.zero
    |> assets.add("", "", 42)
    |> assets.add(policy_a, "x", 10)
    |> assets.add(policy_a, "y", -2)
    |> assets.add(policy_b, "z", 7)

const max_quantity = 170_141_183_460_469_231_731_687_303_715_884_105_727

const min_quantity = -170_141_183_460_469_231_731_687_303_715_884_105_728

// -------------------------------------------------------------------- generators

const default_policies: Fuzzer<List<PolicyId>> =
  fuzz.list_between(
    fuzz.either(fuzz.constant(ada_policy_id), cardano.policy_id()),
    0,
    5,
  )

fn default_asset_name(policy_id: PolicyId) -> Fuzzer<AssetName> {
  if policy_id == ada_policy_id {
    fuzz.constant(ada_asset_name)
  } else {
    cardano.asset_name()
  }
}

fn any_value_with(
  any_policies: Fuzzer<List<PolicyId>>,
  any_asset_name: fn(PolicyId) -> Fuzzer<AssetName>,
  any_quantity: Fuzzer<Int>,
) -> Fuzzer<Value> {
  let policies <- fuzz.and_then(any_policies)
  list.foldr(
    policies,
    fuzz.constant({}),
    fn(policy, step) {
      let value <- fuzz.and_then(step)
      let asset_name <- fuzz.and_then(any_asset_name(policy))
      let quantity <- fuzz.map(any_quantity)
      value |> insert(policy, asset_name, quantity)
    },
  )
}

fn any_value() -> Fuzzer<Value> {
  any_value_with(
    default_policies,
    default_asset_name,
    fuzz.either(
      fuzz.constant(min_quantity),
      fuzz.either(fuzz.constant(max_quantity), fuzz.int()),
    ),
  )
}

fn any_small_value() -> Fuzzer<Value> {
  any_value_with(default_policies, default_asset_name, fuzz.int())
}

fn any_positive_value() -> Fuzzer<Value> {
  any_value_with(
    default_policies,
    default_asset_name,
    fuzz.either(fuzz.constant(max_quantity), fuzz.int_at_least(0)),
  )
}

// ----------------------------------------------------------------- from_assets

test from_assets_1() {
  from_assets(fixture_assets) == fixture_value
}

test from_assets_2() {
  from_assets(assets.zero) == {}
}

test from_assets_3() fail {
  assets.from_asset("", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 1)
    |> from_assets
    |> tautology
}

test from_assets_4() fail {
  assets.from_asset("", "", max_quantity + 1)
    |> from_assets
    |> tautology
}

test from_assets_5() {
  from_assets(assets.from_lovelace(42)) == {
    lovelace: 42,
  }
}

// ------------------------------------------------------------------- from_data

test from_data_1() {
  expect Some(result) = from_data([Pair(#"", [Pair(#"", 42)])])
  quantity_of(result, "", "") == 42
}

test from_data_2() {
  and {
    from_data(1) == None,
    from_data("") == None,
    from_data([Pair(1, 2)]) == None,
    from_data([Pair("", [Pair("", "")])]) == None,
    from_data([("", [("", 1)])]) == None,
    from_data(builtin.list_data([])) == None,
    from_data(builtin.map_data([])) == Some({}),
  }
}

test from_data_3() fail {
  from_data([Pair(#"", [Pair(#"", 0)])]) |> tautology
}

test from_data_4() fail {
  [
    Pair(
      #"",
      [
        Pair(
          #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          1,
        ),
      ],
    ),
  ]
    |> from_data
    |> tautology
}

test from_data_5() fail {
  from_data([Pair(policy_b, [Pair(#"", 1)]), Pair(policy_a, [Pair(#"", 1)])])
    |> tautology
}

// ------------------------------------------------------------ expect_from_data

test expect_from_data_1() {
  lovelace_of(expect_from_data([Pair(#"", [Pair(#"", 42)])])) == 42
}

test expect_from_data_2() fail {
  expect_from_data(42) |> tautology
}

test expect_from_data_3() fail {
  expect_from_data(
    builtin.map_data(
      [builtin.new_pair(builtin.b_data(""), builtin.map_data([]))],
    ),
  )
    |> tautology
}

// -------------------------------------------------------------------- contains

test prop_contains(value via any_positive_value()) {
  and {
    contains(value, {})?,
    contains(value, value)?,
  }
}

test contains_1() {
  contains(
    {
      policy_a: {
        "x": 42,
      },
      policy_b: {
        "y": 1,
      },
    },
    {
      policy_a: {
        "x": 14,
      },
    },
  )
}

test contains_2() {
  !contains(
    zero |> insert(policy_a, "x", 14),
    zero |> insert(policy_a, "x", 42),
  )
}

test contains_3() {
  !contains(zero |> insert(policy_a, "x", 42), zero |> insert(policy_b, "x", 1))
}

test contains_4() fail {
  contains(zero |> insert(policy_a, "x", -1), zero)
}

test contains_5() fail {
  contains(zero, zero |> insert(policy_a, "x", -1))
}

// --------------------------------------------------------------------- is_zero

test prop_eventually_zero(value via any_value()) {
  reduce(
    value,
    value,
    fn(policy_id, asset_name, _, result) {
      delete(result, policy_id, asset_name)
    },
  )
    |> is_zero
}

test is_zero_1() {
  is_zero(zero)
}

test is_zero_2() {
  !is_zero(zero |> insert("", "", 1))
}

// ----------------------------------------------------------------- lovelace_of

test prop_lovelace_of(value via any_value()) {
  or {
    lovelace_of(value) == 0,
    lovelace_of(without_lovelace(value)) == 0,
  }
}

test lovelace_of_1() {
  lovelace_of(fixture_value) == 42
}

test lovelace_of_2() {
  lovelace_of(zero |> insert(policy_a, "", 1)) == 0
}

// -------------------------------------------------------------------- policies

test prop_policies(value via any_value()) {
  let ids = policies(value)
  list.sort(ids, bytearray.compare) == ids
}

test policies_1() {
  policies(fixture_value) == ["", policy_a, policy_b]
}

test policies_2() {
  policies(zero) == []
}

test policies_3() {
  policies(
    {
      lovelace: 42,
    },
  ) == [""]
}

// ----------------------------------------------------------------- quantity_of

test quantity_of_1() {
  quantity_of(fixture_value, policy_a, "x") == 10
}

test quantity_of_2() {
  quantity_of(fixture_value, policy_a, "missing") == 0
}

test quantity_of_3() {
  quantity_of(fixture_value, "missing", "x") == 0
}

test quantity_of_4() {
  quantity_of(
    fixture_value,
    #"0000000000000000000000000000000000000000000000000000000000000000000000000000",
    "x",
  ) == 0
}

// ---------------------------------------------------------------------- delete

test delete_1() {
  let result = zero
    |> insert(policy_a, "x", 1)
    |> insert(policy_a, "y", 2)
    |> delete(policy_a, "x")

  and {
    quantity_of(result, policy_a, "x") == 0,
    quantity_of(result, policy_a, "y") == 2,
  }
}

test delete_2() {
  zero
    |> insert(policy_a, "x", 1)
    |> delete(policy_a, "x")
    |> is_zero
}

test delete_3() {
  delete(fixture_value, "missing", "asset") == fixture_value
}

// ------------------------------------------------------------------------- insert

test insert_1() {
  quantity_of(insert(zero, policy_a, "x", 42), policy_a, "x") == 42
}

test insert_2() {
  quantity_of(
    zero |> insert(policy_a, "x", 42) |> insert(policy_a, "x", 14),
    policy_a,
    "x",
  ) == 14
}

test insert_3() {
  zero
    |> insert(policy_a, "x", 42)
    |> insert(policy_a, "x", 0)
    |> is_zero
}

test insert_4() fail {
  insert(zero, policy_a, "x", max_quantity + 1) |> tautology
}

test insert_5() fail {
  insert(zero, policy_a, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 1) |> tautology
}

// ---------------------------------------------------------------------- negate

test prop_scale_negate(value via any_small_value()) {
  negate(value) == scale(value, -1)
}

test prop_double_negate(value via any_small_value()) {
  negate(negate(value)) == value
}

test negate_1() {
  let result = zero
    |> insert(policy_a, "x", 42)
    |> insert(policy_a, "y", -14)
    |> negate

  and {
    quantity_of(result, policy_a, "x") == -42,
    quantity_of(result, policy_a, "y") == 14,
  }
}

test negate_2() {
  ( fixture_value |> negate |> negate ) == fixture_value
}

test negate_3() fail {
  zero
    |> insert(policy_a, "x", min_quantity)
    |> negate
    |> tautology
}

// --------------------------------------------------------------- restricted_to

test restricted_to_1() {
  restricted_to(fixture_value, [policy_b]) == (
    zero |> insert(policy_b, "z", 7)
  )
}

test restricted_to_2() {
  restricted_to(fixture_value, ["", policy_a]) == (
    zero
      |> insert("", "", 42)
      |> insert(policy_a, "x", 10)
      |> insert(policy_a, "y", -2)
  )
}

test restricted_to_3() {
  restricted_to(fixture_value, []) == zero
}

// ----------------------------------------------------------------------- scale

test scale_1() {
  let result = zero
    |> insert(policy_a, "x", 21)
    |> insert(policy_a, "y", -7)
    |> scale(2)

  and {
    quantity_of(result, policy_a, "x") == 42,
    quantity_of(result, policy_a, "y") == -14,
  }
}

test scale_2() {
  scale(fixture_value, 0) == zero
}

test scale_3() fail {
  zero
    |> insert(policy_a, "x", max_quantity)
    |> scale(2)
    |> is_zero
}

// ------------------------------------------------------------ without_lovelace

test prop_without_lovelace(value via any_value()) {
  lovelace_of(without_lovelace(value)) == 0
}

test without_lovelace_1() {
  without_lovelace(fixture_value) == (
    zero
      |> insert(policy_a, "x", 10)
      |> insert(policy_a, "y", -2)
      |> insert(policy_b, "z", 7)
  )
}

test without_lovelace_2() {
  let without_ada = zero |> insert(policy_a, "x", 1)
  without_lovelace(without_ada) == without_ada
}

// ------------------------------------------------------------------ difference

test difference_1() {
  quantity_of(
    difference(
      zero |> insert(policy_a, "x", 42),
      zero |> insert(policy_a, "x", 14),
    ),
    policy_a,
    "x",
  ) == 28
}

test difference_2() {
  difference(
    zero |> insert(policy_a, "x", 42),
    zero |> insert(policy_a, "x", 42),
  ) == zero
}

test difference_3() {
  quantity_of(
    difference(zero, zero |> insert(policy_a, "x", 42)),
    policy_a,
    "x",
  ) == -42
}

test difference_4() fail {
  difference(zero, zero |> insert(policy_a, "x", min_quantity)) == zero
}

// ----------------------------------------------------------------------- merge

test prop_merge((rhs, lhs) via fuzz.both(any_small_value(), any_small_value())) {
  merge(rhs, lhs) == merge(lhs, rhs)
}

test merge_1() {
  let result = merge(
    zero |> insert(policy_a, "x", 28),
    zero |> insert(policy_a, "x", 14) |> insert(policy_b, "y", 1),
  )

  and {
    quantity_of(result, policy_a, "x") == 42,
    quantity_of(result, policy_b, "y") == 1,
  }
}

test merge_2() {
  merge(zero |> insert(policy_a, "x", 42), zero |> insert(policy_a, "x", -42)) == zero
}

test merge_3() fail {
  merge(
    zero |> insert(policy_a, "x", max_quantity),
    zero |> insert(policy_a, "x", 1),
  )
    |> tautology
}

// ---------------------------------------------------------------------- reduce

test prop_reduce(value via any_value()) {
  let max_asset = #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  reduce(
    value,
    (#"ffffffffffffffffffffffffffffffffffffffffffffffffffffffff", max_asset),
    fn(policy, asset, _, (prev_policy, prev_asset)) {
      expect bytearray.compare(policy, prev_policy) != Greater
      if policy == prev_policy {
        expect bytearray.compare(asset, prev_asset) != Greater
        (policy, asset)
      } else {
        (policy, max_asset)
      }
    },
  )
    |> tautology
}

test reduce_1() {
  reduce(fixture_value, 0, fn(_, _, quantity, total) { quantity + total }) == 57
}

test reduce_2() {
  reduce(
    fixture_value,
    [],
    fn(policy_id, asset_name, _, result) { [(policy_id, asset_name), ..result] },
  ) == [("", ""), (policy_a, "x"), (policy_a, "y"), (policy_b, "z")]
}

test reduce_3() {
  reduce(zero, 42, fn(_, _, quantity, total) { quantity + total }) == 42
}

// --------------------------------------------------------------------- to_data

test to_data_1() {
  to_data(fixture_value) == [
    Pair(#"", [Pair(#"", 42)]),
    Pair(policy_a, [Pair(#"78", 10), Pair(#"79", -2)]),
    Pair(policy_b, [Pair(#"7a", 7)]),
  ]
}

test to_data_2() {
  to_data(zero) == builtin.map_data([])
}

// -------------------------------------------------------------------- to_pairs

test to_pairs_1() {
  to_pairs(fixture_value) == [
    Pair("", [Pair("", 42)]),
    Pair(policy_a, [Pair("x", 10), Pair("y", -2)]),
    Pair(policy_b, [Pair("z", 7)]),
  ]
}

test to_pairs_2() {
  to_pairs(zero) == []
}
