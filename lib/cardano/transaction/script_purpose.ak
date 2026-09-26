use aiken/primitive/bytearray
use aiken/primitive/int
use cardano/address/credential
use cardano/governance/voter
use cardano/transaction.{
  Mint, Propose, Publish, ScriptPurpose, Spend, Vote, Withdraw,
}
use cardano/transaction/output_reference

/// Compare two script purposes, using the same ordering as the one used by
/// the ledger when constructing the
/// [redeemers](./transaction.html#Transaction) list:
///
/// [`Spend`](./transaction.html#ScriptPurpose) < [`Mint`](./transaction.html#ScriptPurpose) < [`Publish`](./transaction.html#ScriptPurpose) < [`Withdraw`](./transaction.html#ScriptPurpose) < [`Vote`](./transaction.html#ScriptPurpose) < [`Propose`](./transaction.html#ScriptPurpose)
///
/// Note that this ordering follows the internal ledger types, and thus
/// differs from the constructor order of
/// [ScriptPurpose](./transaction.html#ScriptPurpose): `Spend` comes before
/// `Mint`, and `Publish` comes before `Withdraw`.
pub fn compare(left: ScriptPurpose, right: ScriptPurpose) -> Ordering {
  when left is {
    Spend(left) ->
      when right is {
        Spend(right) -> output_reference.compare(left, right)
        _ -> Less
      }

    Mint(left) ->
      when right is {
        Mint(right) -> bytearray.compare(left, right)
        Spend(_) -> Greater
        _ -> Less
      }

    Publish { at: left, .. } ->
      when right is {
        Publish { at: right, .. } -> int.compare(left, right)
        Spend(_) | Mint(_) -> Greater
        _ -> Less
      }

    Withdraw(left) ->
      when right is {
        Withdraw(right) -> credential.compare(left, right)
        Spend(_) | Mint(_) | Publish { .. } -> Greater
        _ -> Less
      }

    Vote(left) ->
      when right is {
        Vote(right) -> voter.compare(left, right)
        Propose { .. } -> Less
        _ -> Greater
      }

    Propose { at: left, .. } ->
      when right is {
        Propose { at: right, .. } -> int.compare(left, right)
        _ -> Greater
      }
  }
}
