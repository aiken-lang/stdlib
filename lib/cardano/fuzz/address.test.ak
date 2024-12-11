use aiken/fuzz.{label}
use cardano/address.{Address, Inline, Script, VerificationKey}
use cardano/fuzz/address.{any_address, any_credential} as fuzz_address

test prop_any_credential(c via any_credential()) {
  label(
    when c is {
      Script(_) -> @"Script"
      VerificationKey(_) -> @"VerificationKey"
    },
  )
  True
}

test prop_any_address(a via any_address()) {
  label(
    when a is {
      Address { payment_credential: VerificationKey(_), stake_credential: None } ->
        @"VerificationKey_NoStake"
      Address { payment_credential: Script(_), stake_credential: None } ->
        @"Script_NoStake"
      Address {
        payment_credential: VerificationKey(_),
        stake_credential: Some(Inline(VerificationKey(_))),
      } -> @"VerificationKey_InlineVerificationKey"
      Address {
        payment_credential: VerificationKey(_),
        stake_credential: Some(Inline(Script(_))),
      } -> @"VerificationKey_InlineScript"
      Address {
        payment_credential: Script(_),
        stake_credential: Some(Inline(VerificationKey(_))),
      } -> @"Script_InlineVerificationKey"
      Address {
        payment_credential: Script(_),
        stake_credential: Some(Inline(Script(_))),
      } -> @"Script_InlineScript"
      _ -> fail @"Unexpected Address from any_address"
    },
  )
  True
}
