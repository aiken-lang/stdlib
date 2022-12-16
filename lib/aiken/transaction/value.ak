use aiken/assoc_list.{AssocList}
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
pub const ada_policy_id = #[]

/// A type-alias for 'AssetName`, which are free-form byte-arrays between
/// 0 and 32 bytes.
pub type AssetName =
  ByteArray

/// Ada, the native currency, isn't associated with any `AssetName` (it's not
/// possible to mint Ada!).
///
/// By convention, it is an empty `ByteArray`.
pub const ada_asset_name = #[]

/// An output `Value`, as a key-value pairs of key-value pairs.
///
/// The first level represents policies id (or simply, scripts hashes),
/// and the second layer represents assets within that policy with their
/// respective quantities.
pub type Value =
  AssocList<PolicyId, AssocList<AssetName, Int>>

/// Construct a 'Value' from an asset identifier (i.e. `PolicyId` + `AssetName`)
/// and a given quantity.
pub fn from_asset(policy_id: PolicyId, asset_name: AssetName, quantity: Int) {
  let asset =
    assoc_list.new()
    |> assoc_list.insert(asset_name, quantity)
  assoc_list.new()
  |> assoc_list.insert(policy_id, asset)
}

/// Construct a 'Value' from a lovelace quantity.
///
/// Friendly reminder: 1 Ada = 1.000.000 Lovelace
pub fn from_lovelace(quantity: Int) -> Value {
  from_asset(ada_policy_id, ada_asset_name, quantity)
}

/// Extract the quantity of a given asset.
pub fn quantity_of(
  value: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  value
  |> assoc_list.get(policy_id)
  |> option.and_then(assoc_list.get(_, asset_name))
  |> option.or_else(0)
}

/// A specialized version of `quantity_of` for the Ada currency.
pub fn lovelace_of(value: Value) -> Int {
  quantity_of(value, ada_policy_id, ada_asset_name)
}

/// Flatten a value as list of 3-tuple (PolicyId, AssetName, Quantity).
///
/// Handy to manipulate values as uniform lists.
pub fn flatten(value: Value) -> List<#(PolicyId, AssetName, Int)> {
  assoc_list.fold(
    value,
    fn(policy_id, asset, assets) {
      assoc_list.fold(
        asset,
        fn(asset_name, quantity, xs) {
          [#(policy_id, asset_name, quantity), ..xs]
        },
        assets,
      )
    },
    [],
  )
}
