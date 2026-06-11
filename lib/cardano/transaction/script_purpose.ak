use aiken/primitive/bytearray
use aiken/primitive/int
use cardano/address/credential
use cardano/governance/voter
use cardano/transaction.{
  Mint, Propose, Publish, ScriptPurpose, Spend, Vote, Withdraw,
}
use cardano/transaction/output_reference

pub fn compare(left: ScriptPurpose, right: ScriptPurpose) -> Ordering {
  when left is {
    Spend(left) ->
      when right is {
        Spend(right) -> output_reference.compare(left, right)
        _ -> Less
      }

    Mint(left) ->
      when right is {
        Spend(_) -> Greater
        Mint(right) -> bytearray.compare(left, right)
        _ -> Less
      }

    Publish { at: left, .. } ->
      when right is {
        Spend(_) | Mint(_) -> Greater
        Publish { at: right, .. } -> int.compare(left, right)
        _ -> Less
      }

    Withdraw(left) ->
      when right is {
        Spend(_) | Mint(_) | Publish { .. } -> Greater
        Withdraw(right) -> credential.compare(left, right)
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
