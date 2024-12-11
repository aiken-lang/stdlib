use aiken/collection/list
use aiken/fuzz.{
  and_then, bytearray_between, constant, int_at_least, int_between, list_between,
  map,
}
use cardano/assets.{AssetName, PolicyId, Value, ada_asset_name, ada_policy_id}

pub fn any_asset_name() -> Fuzzer<AssetName> {
  bytearray_between(0, 32)
}

pub fn any_policy_id() -> Fuzzer<PolicyId> {
  bytearray_between(28, 28)
}

pub fn any_ada_only_value() -> Fuzzer<Value> {
  map(int_at_least(1), assets.from_lovelace)
}

pub fn any_assets(policy_id: PolicyId, value: Value) -> Fuzzer<Value> {
  let names <- and_then(list_between(any_asset_name(), 1, 3))
  list.foldr(
    names,
    constant(value),
    fn(asset_name, step) {
      let value <- and_then(step)
      let quantity <- map(int_at_least(1))
      value |> assets.add(policy_id, asset_name, quantity)
    },
  )
}

pub fn any_value_with(forced_policy_id: PolicyId) -> Fuzzer<Value> {
  let value <- and_then(any_ada_only_value())
  let policies <- and_then(list_between(any_policy_id(), 0, 2))
  list.foldr(
    [forced_policy_id, ..policies],
    constant(value),
    fn(policy_id, step) {
      let value <- and_then(step)
      any_assets(policy_id, value)
    },
  )
}

pub fn any_value() -> Fuzzer<Value> {
  let value <- and_then(any_ada_only_value())
  let policies <- and_then(list_between(any_policy_id(), 0, 2))
  list.foldr(
    policies,
    constant(value),
    fn(policy_id, step) {
      let value <- and_then(step)
      any_assets(policy_id, value)
    },
  )
}

pub fn any_value_extending(value: Value) -> Fuzzer<Value> {
  let extra_lovelace <- and_then(int_at_least(1))
  let policies <- and_then(list_between(any_policy_id(), 0, 2))
  list.foldr(
    policies,
    constant(assets.add(value, ada_policy_id, ada_asset_name, extra_lovelace)),
    fn(policy_id, step) {
      let value <- and_then(step)
      any_assets(policy_id, value)
    },
  )
}

// Helper function to generate constrained assets for a single policy
fn any_constrained_assets(
  policy_id: PolicyId,
  asset_constraints: List<Pair<AssetName, Pair<Int, Int>>>,
  initial_value: Value,
) -> Fuzzer<Value> {
  list.foldr(
    asset_constraints,
    constant(initial_value),
    fn(asset_constraint, step) {
      let current_value <- and_then(step)
      let asset_name = asset_constraint.1st
      let min_quantity = asset_constraint.2nd.1st
      let max_quantity = asset_constraint.2nd.2nd
      let quantity <- map(int_between(min_quantity, max_quantity))
      current_value |> assets.add(policy_id, asset_name, quantity)
    },
  )
}

// Updated any_constrained_value function using any_constrained_assets
pub fn any_constrained_value(
  constraints: List<Pair<PolicyId, List<Pair<AssetName, Pair<Int, Int>>>>>,
) -> Fuzzer<Value> {
  let base_value <- and_then(any_ada_only_value())
  list.foldr(
    constraints,
    constant(base_value),
    fn(constraint, step) {
      let value <- and_then(step)
      let policy_id = constraint.1st
      let asset_constraints = constraint.2nd
      any_constrained_assets(policy_id, asset_constraints, value)
    },
  )
}
