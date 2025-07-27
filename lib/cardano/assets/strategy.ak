//// This module contains strategies used to transform [`Value`](../assets.html#Value). You can safely ignore this module if you aren't using [`flatten_with`](../assets.html#flatten_with).

use aiken/crypto.{Blake2b_224, Hash, Script}

/// A strategy for flattening an asset list.
pub type FlattenStrategy<result> =
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

// ### Flatten strategies

/// Keep all assets, combining them as a 3-tuple.
///
/// ```aiken
/// fn(policy_id, asset_name, quantity, keep, _discard) {
///   keep((policy_id, asset_name, quantity))
/// }
/// ```
pub fn triple() -> FlattenStrategy<(Hash<Blake2b_224, Script>, ByteArray, Int)> {
  fn(policy_id, asset_name, quantity, keep, _discard) {
    keep((policy_id, asset_name, quantity))
  }
}
