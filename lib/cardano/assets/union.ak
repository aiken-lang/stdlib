use aiken/crypto.{Blake2b_224, Hash, Script}

/// A strategy for combining two values in a dictionnary that belong to the same key.
pub type UnionStrategy<result> =
  fn(
    Hash<Blake2b_224, Script>,
    ByteArray,
    Int,
    KeepResult<result>,
    DiscardResult<result>,
  ) ->
    List<result>

/// A callback to keep result at a given key
pub type KeepResult<result> =
  fn(result) -> List<result>

/// A callback to discard result at a given key
pub type DiscardResult<result> =
  fn() -> List<result>

/// Combine values by keeping them in a 3-tuple.
pub fn triple() -> UnionStrategy<(Hash<Blake2b_224, Script>, ByteArray, Int)> {
  fn(policy_id, asset_name, quantity, keep, _discard) {
    keep((policy_id, asset_name, quantity))
  }
}
