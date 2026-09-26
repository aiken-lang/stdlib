use aiken/collection/dict.{Dict}
use aiken/collection/dict/strategy as dict_strategy
use aiken/collection/list
use aiken/fuzz
use cardano/assets.{
  AssetName, Assets, PolicyId, ada_asset_name, ada_policy_id, add, difference,
  expect_lovelace_of, expect_match, expect_match_assets, flatten, flatten_with,
  from_ascending_pairs, from_asset, from_asset_list, from_lovelace, has_any_nft,
  has_any_nft_strict, has_nft, has_nft_strict, lovelace_of, match, match_assets,
  merge, negate, reduce, restricted_to, without_lovelace, zero,
}
use cardano/assets/strategy
use cardano/fuzz as cardano

// ---------------------------------------------------------- fixtures & fuzzers

type Tokens =
  Dict<AssetName, Int>

fn any_tokens() -> Fuzzer<Tokens> {
  let tokens <- fuzz.map(fuzz.list_between(any_token(), 0, 3))
  dict.from_pairs(tokens)
}

fn any_token() -> Fuzzer<Pair<AssetName, Int>> {
  let asset_name <- fuzz.and_then(cardano.asset_name())
  let quantity <- fuzz.map(fuzz.int_between(0, 3))
  Pair(asset_name, quantity)
}

fn any_mutation() -> Fuzzer<Mutation> {
  let ix <- fuzz.and_then(fuzz.byte())
  let quantity <- fuzz.and_then(fuzz.int_between(1, 3))
  let name <- fuzz.and_then(cardano.asset_name())
  fuzz.one_of(
    [
      ReduceQuantity(ix, quantity),
      IncreaseQuantity(ix, quantity),
      InsertAsset(Pair(name, quantity)),
      DeleteAsset(ix),
    ],
  )
}

type Mutation {
  ReduceQuantity(Int, Int)
  IncreaseQuantity(Int, Int)
  InsertAsset(Pair<AssetName, Int>)
  DeleteAsset(Int)
}

const fixture_asset_name: AssetName = #"746f6b656e"

const fixture_superset: Tokens = dict.singleton(fixture_asset_name, 100)

const fixture_superset_with_ada: Tokens =
  dict.singleton(fixture_asset_name, 100)

const fixture_subset: Tokens = dict.singleton(fixture_asset_name, 50)

const has_nft_fixture_1: Assets =
  from_lovelace(42)
    |> add("foo", "asset#1", 1)
    |> add("bar", "asset#2", 14)

const has_nft_fixture_2: Assets =
  from_lovelace(42)
    |> add("foo", "asset#1", 1)

const has_nft_fixture_3: Assets =
  from_lovelace(42)
    |> add("foo", "asset#1", 1)
    |> add("foo", "asset#2", 1)
    |> add("bar", "asset#2", 14)

const fixture_match_value: Assets =
  zero
    |> add(ada_policy_id, ada_asset_name, 42)
    |> add("foo", "01", 1)
    |> add("foo", "02", 1)
    |> add("bar", "01", 42)

const fixture_match_data: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)
    |> add("foo", "01", 1)
    |> add("foo", "02", 1)
    |> add("bar", "01", 42)

const fixture_match_data_missing_foo_02: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)
    |> add("foo", "01", 1)
    |> add("bar", "01", 42)

const fixture_match_data_altered_foo_01: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)
    |> add("foo", "01", 14)
    |> add("foo", "02", 1)
    |> add("bar", "01", 42)

const fixture_match_data_missing_bar: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)
    |> add("foo", "01", 1)
    |> add("foo", "02", 1)

const fixture_match_data_extra_policy: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)
    |> add("foo", "01", 1)
    |> add("foo", "02", 1)
    |> add("bar", "01", 42)
    |> add("baz", "01", 1)

const fixture_match_data_extra_asset: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)
    |> add("foo", "01", 1)
    |> add("foo", "02", 1)
    |> add("foo", "03", 1)
    |> add("bar", "01", 42)

const fixture_match_data_no_assets: Data =
  zero
    |> add(ada_policy_id, ada_asset_name, 14)

const fixture_match_benchmark_left: Assets =
  zero
    |> add(ada_policy_id, ada_asset_name, 1337)
    |> add(
        #"0246a14d04c3a0e9b65f6b90a3d1aa5faee5d56ab1e30ec7e8b02f29",
        "MATTR",
        200,
      )
    |> add(
        #"0a9e126256cb38c4865cdac6eb2ada51c328ba0df2ebde22ae126c0d",
        "ProphecyPoster076",
        1,
      )
    |> add(
        #"1774343241680e4daef7cbfe3536fc857ce23fb66cd0b66320b2e3dd",
        "BISON",
        12_004_999_999,
      )
    |> add(
        #"279c909f348e533da5808898f87f9a14bb2c3dfbbacccd631d927a3f",
        "SNEK",
        1486,
      )
    |> add(
        #"651dfc074202423585996ffa717cb45237d307e705e2cc3dab1ccabd",
        "MAYZSilverFoundersEdition0035",
        1,
      )
    |> add(
        #"63df49056617dd14034986cf7c250bad6552fd2f0f9c71d797932008",
        "CardanoSpaceSession",
        20,
      )
    |> add(
        #"5b01968867e13432afaa2f814e1d15e332d6cd0aa77e350972b0967d",
        "ADAOGovernanceToken",
        1,
      )
    |> add(
        #"a0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235",
        "HOSKY",
        400_001_000,
      )
    |> add(
        #"da8c30857834c6ae7203935b89278c532b3995245295456f993e1d24",
        "LQ",
        10_635_899,
      )
    |> add(
        #"95d9a98c2f7999a3d5e0f4d795cb1333837c09eb0f24835cd2ce954c",
        "GrandmasterAdventurer659",
        1,
      )
    |> add(
        #"702cbdb06a81ef2fa4f85f9e32159c03f502539d762a71194fc11eb3",
        "AdventurerOfThiolden8105",
        1,
      )
    |> add(
        #"d0112837f8f856b2ca14f69b375bc394e73d146fdadcc993bb993779",
        "DiscoSolaris3725",
        1,
      )
    |> add(
        #"8dd5717e7d4d993019dbd788c19837910e3fcf647ab282f828c80a7a",
        "CardaWorld535",
        1,
      )
    |> add(
        #"8dd5717e7d4d993019dbd788c19837910e3fcf647ab282f828c80a7a",
        "CardaWorld1213",
        1,
      )
    |> add(
        #"8dd5717e7d4d993019dbd788c19837910e3fcf647ab282f828c80a7a",
        "CardaWorld1518",
        1,
      )
    |> add(
        #"8dd5717e7d4d993019dbd788c19837910e3fcf647ab282f828c80a7a",
        "CardaWorld1537",
        1,
      )
    |> add(
        #"8dd5717e7d4d993019dbd788c19837910e3fcf647ab282f828c80a7a",
        "CardaWorld4199",
        1,
      )
    |> add(
        #"8dd5717e7d4d993019dbd788c19837910e3fcf647ab282f828c80a7a",
        "CardaWorld3767",
        1,
      )
    |> add(
        #"7597444754551a8c17edbf7291cdaeca898ca02ee4e732b09a949396",
        "Algae1",
        1,
      )
    |> add(
        #"7597444754551a8c17edbf7291cdaeca898ca02ee4e732b09a949396",
        "Algae2",
        1,
      )

const fixture_match_benchmark_right: Data = fixture_match_benchmark_left

const fixture_lovelace_of_1: Assets =
  zero
    |> add("", "", 42)

const fixture_lovelace_of_2: Assets =
  zero
    |> add("foo", "bar", 42)

// --------------------------------------------------------------------- helpers

// Invariant: assume 'tokens' is not empty.
fn apply_mutation(mutation: Mutation, tokens: Tokens) -> Tokens {
  let len = dict.size(tokens)
  when mutation is {
    ReduceQuantity(ix, n) | IncreaseQuantity(ix, n) -> {
      expect [Pair(name, quantity), ..] = list.drop(
        dict.to_pairs(tokens),
        ix % len,
      )
      let new_quantity = if mutation == ReduceQuantity(ix, n) {
        quantity - n
      } else {
        quantity + n
      }
      dict.insert(tokens, name, new_quantity)
    }
    InsertAsset(Pair(name, quantity)) ->
      dict.insert_with(tokens, name, quantity, dict_strategy.sum())
    DeleteAsset(ix) -> {
      expect [Pair(name, _), ..] = list.drop(dict.to_pairs(tokens), ix % len)
      dict.delete(tokens, name)
    }
  }
}

fn tautology(a: a) -> Bool {
  a == a
}

// -------------------------------------------------------- from_ascending_pairs

test from_ascending_pairs_1() {
  let v = from_ascending_pairs([])
  v == zero
}

test from_ascending_pairs_10() fail {
  from_ascending_pairs(
    [Pair(#"", dict.singleton("", 1)), Pair(#"", dict.singleton("", -1))],
  )
    |> tautology
}

test from_ascending_pairs_2() fail {
  from_ascending_pairs([Pair(#"33", dict.empty)])
    |> tautology
}

test from_ascending_pairs_3() fail {
  from_ascending_pairs([Pair(#"33", dict.singleton("", 0))])
    |> tautology
}

test from_ascending_pairs_4() {
  let v = from_ascending_pairs([Pair(#"33", dict.singleton(#"", 1))])
  flatten(v) == [(#"33", #"", 1)]
}

test from_ascending_pairs_5() {
  let v = from_ascending_pairs(
    [Pair(#"33", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"33", 1)]))],
  )
  flatten(v) == [(#"33", #"", 1), (#"33", #"33", 1)]
}

test from_ascending_pairs_6() fail {
  from_ascending_pairs(
    [
      Pair(#"33", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"33", 1)])),
      Pair(#"33", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"33", 1)])),
    ],
  )
    |> tautology
}

test from_ascending_pairs_7() fail {
  from_ascending_pairs(
    [
      Pair(#"33", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"33", 1)])),
      Pair(#"34", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"", 1)])),
    ],
  )
    |> tautology
}

test from_ascending_pairs_8() {
  let v = from_ascending_pairs(
    [
      Pair(#"33", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"33", 1)])),
      Pair(#"34", dict.singleton(#"31", 1)),
      Pair(#"35", dict.singleton("", 1)),
    ],
  )
  flatten(v) == [
    (#"33", #"", 1), (#"33", #"33", 1), (#"34", #"31", 1), (#"35", #"", 1),
  ]
}

test from_ascending_pairs_9() fail {
  from_ascending_pairs(
    [
      Pair(#"35", dict.singleton("", 1)),
      Pair(#"33", dict.from_ascending_pairs([Pair(#"", 1), Pair(#"33", 1)])),
      Pair(#"34", dict.singleton(#"31", 1)),
    ],
  )
    |> tautology
}

// ------------------------------------------------------------- from_asset_list

test from_asset_list_1() {
  let v = from_asset_list([])
  v == zero
}

test from_asset_list_10() fail {
  from_asset_list([Pair(#"", [Pair(#"", 1)]), Pair(#"", [Pair(#"", -1)])])
    |> tautology
}

test from_asset_list_11() fail {
  from_asset_list([Pair(#"", [Pair(#"", 1), Pair(#"", -1)])]) |> tautology
}

test from_asset_list_2() fail {
  from_asset_list([Pair(#"33", [])]) |> tautology
}

test from_asset_list_3() fail {
  from_asset_list([Pair(#"33", [Pair(#"", 0)])]) |> tautology
}

test from_asset_list_4() {
  let v = from_asset_list([Pair(#"33", [Pair(#"", 1)])])
  flatten(v) == [(#"33", #"", 1)]
}

test from_asset_list_5() {
  let v = from_asset_list([Pair(#"33", [Pair(#"", 1), Pair(#"33", 1)])])
  flatten(v) == [(#"33", #"", 1), (#"33", #"33", 1)]
}

test from_asset_list_6() fail {
  from_asset_list(
    [
      Pair(#"33", [Pair(#"", 1), Pair(#"33", 1)]),
      Pair(#"33", [Pair(#"", 1), Pair(#"33", 1)]),
    ],
  )
    |> tautology
}

test from_asset_list_7() fail {
  from_asset_list(
    [
      Pair(#"33", [Pair(#"", 1), Pair(#"33", 1)]),
      Pair(#"34", [Pair(#"", 1), Pair(#"", 1)]),
    ],
  )
    |> tautology
}

test from_asset_list_8() {
  let v = from_asset_list(
    [
      Pair(#"33", [Pair(#"", 1), Pair(#"33", 1)]), Pair(#"34", [Pair(#"31", 1)]),
      Pair(#"35", [Pair(#"", 1)]),
    ],
  )
  flatten(v) == [
    (#"33", #"", 1), (#"33", #"33", 1), (#"34", #"31", 1), (#"35", #"", 1),
  ]
}

test from_asset_list_9() {
  let v = from_asset_list(
    [
      Pair(#"35", [Pair(#"", 1)]), Pair(#"33", [Pair(#"", 1), Pair(#"33", 1)]),
      Pair(#"34", [Pair(#"31", 1)]),
    ],
  )
  flatten(v) == [
    (#"33", #"", 1), (#"33", #"33", 1), (#"34", #"31", 1), (#"35", #"", 1),
  ]
}

// -------------------------------------------------------------------- contains

test contains_exact_match() {
  assets.contains(fixture_superset, fixture_superset)
}

test contains_insufficient() {
  !assets.contains(fixture_subset, fixture_superset)
}

test contains_subset() {
  and {
    assets.contains(fixture_superset, fixture_subset)?,
    assets.contains(fixture_superset_with_ada, fixture_subset)?,
  }
}

test prop_contains_monoid(tokens via any_tokens()) {
  assets.contains(tokens, dict.empty)
}

test prop_contains_reflexive(tokens via any_tokens()) {
  assets.contains(tokens, tokens)
}

test prop_contains_subset_mutation(
  (superset, mutation) via fuzz.both(any_tokens(), any_mutation()),
) fail {
  if superset != dict.empty {
    let subset = apply_mutation(mutation, superset)
    when mutation is {
      IncreaseQuantity(..) -> {
        fuzz.label(@"non-empty superset, increase quantity")
        assets.contains(superset, subset)
      }
      InsertAsset(..) -> {
        fuzz.label(@"non-empty superset, insert new asset")
        assets.contains(superset, subset)
      }
      ReduceQuantity(..) -> {
        fuzz.label(@"non-empty superset, reduce quantity")
        !assets.contains(superset, subset)
      }
      DeleteAsset(..) -> {
        fuzz.label(@"non-empty superset, remove asset")
        !assets.contains(superset, subset)
      }
    }
  } else {
    fuzz.label(@"empty superset, skipped")
    False
  }
}

test prop_contains_superset_mutation(
  (subset, mutation) via fuzz.both(any_tokens(), any_mutation()),
) fail {
  if dict.empty != subset {
    let superset = apply_mutation(mutation, subset)
    when mutation is {
      IncreaseQuantity(..) -> {
        fuzz.label(@"non-empty subset, increase quantity")
        !assets.contains(superset, subset)
      }
      InsertAsset(..) -> {
        fuzz.label(@"non-empty subset, insert new asset")
        !assets.contains(superset, subset)
      }
      ReduceQuantity(..) -> {
        fuzz.label(@"non-empty subset, reduce quantity")
        assets.contains(superset, subset)
      }
      DeleteAsset(..) -> {
        fuzz.label(@"non-empty subset, remove asset")
        assets.contains(superset, subset)
      }
    }
  } else {
    fuzz.label(@"empty subset, skipped")
    False
  }
}

// --------------------------------------------------------------------- has_nft

test has_nft_with_fixture_1() {
  and {
    // has_any_nft
    has_any_nft(has_nft_fixture_1, "foo")?,
    (!has_any_nft(has_nft_fixture_1, "bar"))?,
    (!has_any_nft(has_nft_fixture_1, "baz"))?,
    // has_any_nft_strict
    (!has_any_nft_strict(has_nft_fixture_1, "foo"))?,
    (!has_any_nft_strict(has_nft_fixture_1, "bar"))?,
    (!has_any_nft_strict(has_nft_fixture_1, "baz"))?,
    // has_nft
    has_nft(has_nft_fixture_1, "foo", "asset#1")?,
    (!has_nft(has_nft_fixture_1, "foo", "asset#2"))?,
    (!has_nft(has_nft_fixture_1, "bar", "asset#2"))?,
    (!has_nft(has_nft_fixture_1, "baz", "asset#1"))?,
    // has_nft_strict
    (!has_nft_strict(has_nft_fixture_1, "foo", "asset#1"))?,
    (!has_nft_strict(has_nft_fixture_1, "foo", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_1, "bar", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_1, "baz", "asset#1"))?,
  }
}

test has_nft_with_fixture_1_without_lovelace() {
  let has_nft_fixture_1 = without_lovelace(has_nft_fixture_1)
  and {
    // has_any_nft
    has_any_nft(has_nft_fixture_1, "foo")?,
    (!has_any_nft(has_nft_fixture_1, "bar"))?,
    (!has_any_nft(has_nft_fixture_1, "baz"))?,
    // has_any_nft_strict
    (!has_any_nft_strict(has_nft_fixture_1, "foo"))?,
    (!has_any_nft_strict(has_nft_fixture_1, "bar"))?,
    (!has_any_nft_strict(has_nft_fixture_1, "baz"))?,
    // has_nft
    has_nft(has_nft_fixture_1, "foo", "asset#1")?,
    (!has_nft(has_nft_fixture_1, "foo", "asset#2"))?,
    (!has_nft(has_nft_fixture_1, "bar", "asset#2"))?,
    (!has_nft(has_nft_fixture_1, "baz", "asset#1"))?,
    // has_nft_strict
    (!has_nft_strict(has_nft_fixture_1, "foo", "asset#1"))?,
    (!has_nft_strict(has_nft_fixture_1, "foo", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_1, "bar", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_1, "baz", "asset#1"))?,
  }
}

test has_nft_with_fixture_2() {
  and {
    // has_any_nft
    has_any_nft(has_nft_fixture_2, "foo")?,
    (!has_any_nft(has_nft_fixture_2, "bar"))?,
    (!has_any_nft(has_nft_fixture_2, "baz"))?,
    // has_any_nft_strict
    has_any_nft_strict(has_nft_fixture_2, "foo")?,
    (!has_any_nft_strict(has_nft_fixture_2, "bar"))?,
    (!has_any_nft_strict(has_nft_fixture_2, "baz"))?,
    // has_nft
    has_nft(has_nft_fixture_2, "foo", "asset#1")?,
    (!has_nft(has_nft_fixture_2, "foo", "asset#2"))?,
    (!has_nft(has_nft_fixture_2, "bar", "asset#2"))?,
    (!has_nft(has_nft_fixture_2, "baz", "asset#1"))?,
    // has_nft_strict
    has_nft_strict(has_nft_fixture_2, "foo", "asset#1")?,
    (!has_nft_strict(has_nft_fixture_2, "foo", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_2, "bar", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_2, "baz", "asset#1"))?,
  }
}

test has_nft_with_fixture_2_without_lovelace() {
  let has_nft_fixture_2 = without_lovelace(has_nft_fixture_2)
  and {
    // has_any_nft
    has_any_nft(has_nft_fixture_2, "foo")?,
    (!has_any_nft(has_nft_fixture_2, "bar"))?,
    (!has_any_nft(has_nft_fixture_2, "baz"))?,
    // has_any_nft_strict
    has_any_nft_strict(has_nft_fixture_2, "foo")?,
    (!has_any_nft_strict(has_nft_fixture_2, "bar"))?,
    (!has_any_nft_strict(has_nft_fixture_2, "baz"))?,
    // has_nft
    has_nft(has_nft_fixture_2, "foo", "asset#1")?,
    (!has_nft(has_nft_fixture_2, "foo", "asset#2"))?,
    (!has_nft(has_nft_fixture_2, "bar", "asset#2"))?,
    (!has_nft(has_nft_fixture_2, "baz", "asset#1"))?,
    // has_nft_strict
    has_nft_strict(has_nft_fixture_2, "foo", "asset#1")?,
    (!has_nft_strict(has_nft_fixture_2, "foo", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_2, "bar", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_2, "baz", "asset#1"))?,
  }
}

test has_nft_with_fixture_3() {
  and {
    // has_any_nft
    has_any_nft(has_nft_fixture_3, "foo")?,
    (!has_any_nft(has_nft_fixture_3, "bar"))?,
    (!has_any_nft(has_nft_fixture_3, "baz"))?,
    // has_any_nft_strict
    (!has_any_nft_strict(has_nft_fixture_3, "foo"))?,
    (!has_any_nft_strict(has_nft_fixture_3, "bar"))?,
    (!has_any_nft_strict(has_nft_fixture_3, "baz"))?,
    // has_nft
    has_nft(has_nft_fixture_3, "foo", "asset#1")?,
    has_nft(has_nft_fixture_3, "foo", "asset#2")?,
    (!has_nft(has_nft_fixture_3, "bar", "asset#2"))?,
    (!has_nft(has_nft_fixture_3, "baz", "asset#1"))?,
    // has_nft_strict
    (!has_nft_strict(has_nft_fixture_3, "foo", "asset#1"))?,
    (!has_nft_strict(has_nft_fixture_3, "foo", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_3, "bar", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_3, "baz", "asset#1"))?,
  }
}

test has_nft_with_fixture_3_without_lovelace() {
  let has_nft_fixture_3 = without_lovelace(has_nft_fixture_3)
  and {
    // has_any_nft
    has_any_nft(has_nft_fixture_3, "foo")?,
    (!has_any_nft(has_nft_fixture_3, "bar"))?,
    (!has_any_nft(has_nft_fixture_3, "baz"))?,
    // has_any_nft_strict
    (!has_any_nft_strict(has_nft_fixture_3, "foo"))?,
    (!has_any_nft_strict(has_nft_fixture_3, "bar"))?,
    (!has_any_nft_strict(has_nft_fixture_3, "baz"))?,
    // has_nft
    has_nft(has_nft_fixture_3, "foo", "asset#1")?,
    has_nft(has_nft_fixture_3, "foo", "asset#2")?,
    (!has_nft(has_nft_fixture_3, "bar", "asset#2"))?,
    (!has_nft(has_nft_fixture_3, "baz", "asset#1"))?,
    // has_nft_strict
    (!has_nft_strict(has_nft_fixture_3, "foo", "asset#1"))?,
    (!has_nft_strict(has_nft_fixture_3, "foo", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_3, "bar", "asset#2"))?,
    (!has_nft_strict(has_nft_fixture_3, "baz", "asset#1"))?,
  }
}

// ----------------------------------------------------------------------- match

test match_1() {
  match(fixture_match_value, fixture_match_data, fn(_, _) { True })
}

test match_10() {
  match(
    without_lovelace(fixture_match_value),
    without_lovelace(fixture_match_value),
    fn(left, right) { left == 0 && right == 0 },
  )
}

test match_11() {
  match(
    without_lovelace(fixture_match_value),
    fixture_match_value,
    fn(left, right) { left == 0 && right > 0 },
  )
}

test match_12() {
  match(
    fixture_match_value,
    without_lovelace(fixture_match_value),
    fn(left, right) { left > 0 && right == 0 },
  )
}

test match_13() {
  match(
    zero |> add(ada_policy_id, ada_asset_name, 42),
    zero,
    fn(left, right) { left == 42 && right == 0 },
  )
}

test match_14() {
  match(
    zero,
    zero |> add(ada_policy_id, ada_asset_name, 42),
    fn(left, right) { left == 0 && right == 42 },
  )
}

test match_2() {
  !match(
    fixture_match_value,
    fixture_match_data,
    fn(source, target) { source == target },
  )
}

test match_3() {
  !match(
    fixture_match_value,
    fixture_match_data_missing_foo_02,
    fn(_, _) { True },
  )
}

test match_4() {
  !match(fixture_match_value, fixture_match_data_missing_bar, fn(_, _) { True })
}

test match_5() {
  !match(
    fixture_match_value,
    fixture_match_data_altered_foo_01,
    fn(_, _) { True },
  )
}

test match_6() {
  !match(
    fixture_match_value,
    fixture_match_data_extra_policy,
    fn(_, _) { True },
  )
}

test match_7() {
  !match(fixture_match_value, fixture_match_data_extra_asset, fn(_, _) { True })
}

test match_8() {
  !match(fixture_match_value, fixture_match_data_no_assets, fn(_, _) { True })
}

test match_9() {
  match(zero, zero, ==)
}

test match_bench() {
  match(fixture_match_benchmark_left, fixture_match_benchmark_right, ==)
}

// ---------------------------------------------------------------- match_assets

test match_assets_1() {
  match_assets(fixture_match_value, fixture_match_data)
}

test match_assets_10() {
  match_assets(without_lovelace(fixture_match_value), fixture_match_value)
}

test match_assets_11() {
  match_assets(fixture_match_value, without_lovelace(fixture_match_value))
}

test match_assets_12() {
  match_assets(zero |> add(ada_policy_id, ada_asset_name, 42), zero)
}

test match_assets_13() {
  match_assets(zero, zero |> add(ada_policy_id, ada_asset_name, 42))
}

test match_assets_2() {
  !match_assets(fixture_match_value, fixture_match_data_missing_foo_02)
}

test match_assets_3() {
  !match_assets(fixture_match_value, fixture_match_data_missing_bar)
}

test match_assets_4() {
  !match_assets(fixture_match_value, fixture_match_data_altered_foo_01)
}

test match_assets_5() {
  !match_assets(fixture_match_value, fixture_match_data_extra_policy)
}

test match_assets_6() {
  !match_assets(fixture_match_value, fixture_match_data_extra_asset)
}

test match_assets_7() {
  !match_assets(fixture_match_value, fixture_match_data_no_assets)
}

test match_assets_8() {
  match_assets(zero, zero)
}

test match_assets_9() {
  match_assets(
    without_lovelace(fixture_match_value),
    without_lovelace(fixture_match_value),
  )
}

test match_assets_bench() {
  match_assets(fixture_match_benchmark_left, fixture_match_benchmark_right)
}

// ----------------------------------------------------------------- lovelace_of

test lovelace_of_0() {
  lovelace_of(zero) == 0
}

test lovelace_of_1() {
  lovelace_of(fixture_lovelace_of_1) == 42
}

test lovelace_of_2() {
  lovelace_of(fixture_lovelace_of_2) == 0
}

// ---------------------------------------------------------- expect_lovelace_of

test expect_lovelace_of_0() fail {
  expect_lovelace_of(zero) |> tautology
}

test expect_lovelace_of_1() {
  expect_lovelace_of(fixture_lovelace_of_1) == 42
}

test expect_lovelace_of_2() fail {
  expect_lovelace_of(fixture_lovelace_of_2) |> tautology
}

// ---------------------------------------------------------------- expect_match

test expect_match_bench() {
  expect_match(fixture_match_benchmark_left, fixture_match_benchmark_right, ==)
}

// --------------------------------------------------------- expect_match_assets

test expect_match_assets_bench() {
  expect_match_assets(
    fixture_match_benchmark_left,
    fixture_match_benchmark_right,
  )
}

// --------------------------------------------------------------- restricted_to

test restricted_to_1() {
  let self = from_lovelace(42) |> add("foo", "", 1)
  restricted_to(self, []) == zero
}

test restricted_to_2() {
  let self = from_lovelace(42) |> add("foo", "", 1)
  restricted_to(self, [ada_policy_id]) == from_lovelace(42)
}

test restricted_to_3() {
  let self = from_lovelace(42) |> add("foo", "", 1) |> add("bar", "", 1)
  restricted_to(self, ["foo", "bar"]) == without_lovelace(self)
}

test restricted_to_4() {
  let self = from_lovelace(42) |> add("foo", "bar", 1) |> add("foo", "baz", 1)
  restricted_to(self, ["foo"]) == without_lovelace(self)
}

test restricted_to_5() {
  let self = from_lovelace(42) |> add("foo", "bar", 1) |> add("foo", "baz", 1)
  restricted_to(self, [ada_policy_id, "foo"]) == self
}

// ------------------------------------------------------------ without_lovelace

test without_lovelace_1() {
  let v = from_lovelace(1000000)
  without_lovelace(v) == zero
}

test without_lovelace_2() {
  let v = from_lovelace(1000000)
  let v2 = from_lovelace(50000000)
  without_lovelace(v) == without_lovelace(v2)
}

test without_lovelace_3() {
  let v = from_asset(#"010203", #"040506", 100)
    |> add(ada_policy_id, ada_asset_name, 100000000)
  let v2 = from_asset(#"010203", #"040506", 100)
  without_lovelace(v) == without_lovelace(v2) && without_lovelace(v) == v2
}

// ------------------------------------------------------------------------- add

test add_1() {
  let v = zero
    |> add(#"acab", #"beef", 321)
    |> add(#"acab", #"beef", -321)
  v == zero
}

test add_2() {
  let v = from_lovelace(123)
    |> add(#"acab", #"beef", 321)
    |> add(#"acab", #"beef", -1 * 321)
  v == from_lovelace(123)
}

test add_3() {
  let v = from_lovelace(1)
    |> add(ada_policy_id, ada_asset_name, 2)
    |> add(ada_policy_id, ada_asset_name, 3)
  v == from_lovelace(6)
}

test add_4() {
  let v = zero
    |> add(#"acab", #"beef", 0)
  v == zero
}

test add_5() {
  let v = zero
    |> add(#"acab", #"beef", 0)
    |> add(#"acab", #"beef", 0)
  v == zero
}

// ------------------------------------------------------------------ difference

test difference_1() {
  let v0 = from_lovelace(5)
  let v1 = from_lovelace(3)

  let diff = from_lovelace(2)

  and {
    (difference(v0, v1) == diff)?,
    (merge(v0, negate(v1)) == diff)?,
  }
}

test difference_2() {
  let v = zero
    |> add(#"acab", #"beef", 321)
    |> add(#"f00d", #"cafe", 42)

  and {
    (difference(v, v) == zero)?,
    (merge(v, negate(v)) == zero)?,
  }
}

test difference_3() {
  let left = zero |> add(#"00", #"aa", 5)
  let right = zero |> add(#"01", #"bb", 3)

  let diff = [(#"00", #"aa", 5), (#"01", #"bb", -3)]

  and {
    (flatten(difference(left, right)) == diff)?,
    (flatten(merge(left, negate(right))) == diff)?,
  }
}

test difference_4() {
  let left = zero
    |> add(#"00", #"aa", 10)
    |> add(#"00", #"bb", 4)

  let right = zero
    |> add(#"00", #"aa", 10)
    |> add(#"00", #"bb", 1)

  let diff = [(#"00", #"bb", 3)]

  and {
    (flatten(difference(left, right)) == diff)?,
    (flatten(merge(left, negate(right))) == diff)?,
  }
}

// ----------------------------------------------------------------------- merge

test merge_1() {
  let v1 = from_lovelace(1)
  let v2 = from_lovelace(-1)
  merge(v1, v2) == zero
}

test merge_2() {
  let v1 = from_asset(#"00", #"", 1)
  let v2 = from_asset(#"01", #"", 2)
  let v3 = from_asset(#"02", #"", 3)
  let v = from_lovelace(42)
    |> merge(v3)
    |> merge(v1)
    |> merge(v2)

  flatten(v) == [
    (#"", #"", 42), (#"00", #"", 1), (#"01", #"", 2), (#"02", #"", 3),
  ]
}

test merge_3() {
  let v1 = from_asset(#"00", #"", 1)
  let v2 = from_asset(#"00", #"", -1)
  let v3 = from_asset(#"01", #"", 1)

  let v = zero
    |> merge(v1)
    |> merge(v2)
    |> merge(v3)

  flatten(v) == [(#"01", #"", 1)]
}

test merge_4() {
  let v1 = from_asset(#"00", #"", 1)
  let v2 = from_asset(#"00", #"", -1)

  merge(v1, v2) == zero
}

test merge_5() {
  let v = zero
    |> add(#"acab", #"beef", 0)

  merge(zero, v) == zero
}

// ---------------------------------------------------------------- flatten_with

test flatten_with_1() {
  flatten_with(zero, strategy.triple()) == []
}

test flatten_with_2() {
  let v = zero
    |> add("a", "1", 14)
    |> add("b", "", 42)
    |> add("a", "2", 42)

  flatten_with(
    v,
    fn(p, a, q, keep, discard) {
      if q == 42 {
        keep((p, a))
      } else {
        discard()
      }
    },
  ) == [("a", "2"), ("b", "")]
}

// ---------------------------------------------------------------------- reduce

test reduce_1() {
  let v = zero
    |> add("a", "1", 10)
    |> add("b", "2", 20)
  let result = reduce(v, 0, fn(_, _, quantity, acc) { acc + quantity })
  result == 30
}

test reduce_2() {
  let v = zero
    |> add("a", "1", 5)
    |> add("a", "2", 15)
    |> add("b", "", 10)
  let result = reduce(
    v,
    [],
    fn(policy_id, asset_name, _, acc) { [(policy_id, asset_name), ..acc] },
  )
  result == [("a", "1"), ("a", "2"), ("b", "")]
}

test reduce_3() {
  let v = zero
  let result = reduce(v, 1, fn(_, _, quantity, acc) { acc + quantity })
  result == 1
}

// ----------------------------------------------------------------- naive_match

test naive_match_bench() {
  let data: Data = fixture_match_benchmark_right
  expect pairs: Pairs<PolicyId, Pairs<AssetName, Int>> = data
  fixture_match_benchmark_left == from_asset_list(pairs)
}
