use aiken/collection/dict
use aiken/collection/list
use aiken/fuzz.{and_then, int_at_least, int_between, list_between, map}
use cardano/assets.{AssetName, PolicyId, Value}
use cardano/fuzz/assets.{
  any_asset_name, any_constrained_value, any_policy_id, any_value,
  any_value_extending, any_value_with,
} as fuzz_assets

fn help_prop_any_value_with() -> Fuzzer<(assets.PolicyId, assets.Value)> {
  let policy <- and_then(any_policy_id())
  map(any_value_with(policy), fn(b) { (policy, b) })
}

test prop_any_value_with((policy, value) via help_prop_any_value_with()) {
  assets.tokens(value, policy) != dict.empty
}

fn help_prop_any_value_extending() -> Fuzzer<(assets.Value, assets.Value)> {
  let v <- and_then(any_value())
  map(any_value_extending(v), fn(ve) { (v, ve) })
}

test prop_any_value_extending(
  (value, value_extended) via help_prop_any_value_extending(),
) {
  assets.reduce(
    value,
    True,
    fn(p, a, i, r) { r && assets.quantity_of(value_extended, p, a) >= i },
  )
}

/// Helper function to generate asset constraints for a single policy
fn any_asset_constraint() -> Fuzzer<Pair<AssetName, Pair<Int, Int>>> {
  let min_quantity <- and_then(int_at_least(0))
  let max_quantity <- and_then(int_between(min_quantity, min_quantity + 100))
  map(any_asset_name(), fn(a) { Pair(a, Pair(min_quantity, max_quantity)) })
}

/// Helper function to generate constraints for a single policy
fn any_policy_constraints() -> Fuzzer<
  Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>,
> {
  let asset_constraints <- and_then(list_between(any_asset_constraint(), 1, 10))
  map(any_policy_id(), fn(p) { Pair(p, asset_constraints) })
}

/// Helper function to generate a list of policy constraints
fn any_constraints() -> Fuzzer<
  List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>>,
> {
  list_between(any_policy_constraints(), 1, 5)
}

/// Fuzzer to generate constraints along with a constrained value
fn help_prop_any_constrained_value() -> Fuzzer<
  Pair<List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>>, Value>,
> {
  let constraints <- and_then(any_constraints())
  let merged = merge_policy_constraints(constraints)
  let a_c_v = any_constrained_value(merged)
  map(a_c_v, fn(v) { Pair(merged, v) })
}

///
/// Function to merge multiple constraints for the same asset within the same policy
fn merge_asset_constraints(
  asset_constraints: List<Pair<AssetName, Pair<Int, Int>>>,
) -> List<Pair<AssetName, Pair<Int, Int>>> {
  let grouped =
    list.foldr(
      asset_constraints,
      dict.empty,
      fn(pair, acc) {
        let Pair(asset_name, Pair(min, max)) = pair
        when dict.pop(acc, asset_name) is {
          (Some(Pair(existing_min, existing_max)), acc) -> {
            let new_min =
              if min < existing_min {
                min
              } else {
                existing_min
              }
            let new_max =
              if max > existing_max {
                max
              } else {
                existing_max
              }
            dict.insert(acc, asset_name, Pair(new_min, new_max))
          }
          (None, acc) -> dict.insert(acc, asset_name, Pair(min, max))
        }
      },
    )
  dict.to_pairs(grouped)
}

/// Function to merge multiple PolicyIds and their asset constraints into unique PolicyIds with merged asset constraints
fn merge_policy_constraints(
  constraints: List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>>,
) -> List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>> {
  // Group all asset constraints by PolicyId
  let grouped_policies =
    list.foldr(
      constraints,
      dict.empty,
      fn(pair, acc) {
        let Pair(policy_id, asset_constraints) = pair
        when dict.pop(acc, policy_id) is {
          (Some(existing_constraints), acc) ->
            dict.insert(
              acc,
              policy_id,
              list.concat(asset_constraints, existing_constraints),
            )
          (None, acc) -> dict.insert(acc, policy_id, asset_constraints)
        }
      },
    )

  // For each PolicyId, merge its asset constraints
  // let l_acc: List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>> = []
  let merged_policies =
    dict.foldr(
      grouped_policies,
      [],
      fn(policy_id, asset_constraints, acc) {
        let merged_assets = merge_asset_constraints(asset_constraints)
        list.push(acc, Pair(policy_id, merged_assets))
      },
    )
  merged_policies
}

///
fn verify_constraints(
  constraints: List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>>,
  value: Value,
) -> Bool {
  list.all(
    constraints,
    fn(constraint) {
      let Pair(policy_id, asset_constraints) = constraint
      let tokens = assets.tokens(value, policy_id)
      list.all(
        asset_constraints,
        fn(asset_constraint) {
          let Pair(asset_name, Pair(min, max)) = asset_constraint
          when dict.get(tokens, asset_name) is {
            Some(quantity) -> quantity >= min && quantity <= max
            None -> min <= 0
          }
        },
      )
    },
  )
}

test prop_any_constrained_value(
  Pair(constraints, value) via help_prop_any_constrained_value(),
) {
  // Assert that all constraints are satisfied
  verify_constraints(constraints, value)
}
