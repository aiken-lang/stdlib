use aiken/fuzz.{and_then, bool, bytearray_between, int_between, map, map2}
use cardano/address.{Address, Credential, Inline, Script, VerificationKey}

/// Generate a random Credential
pub fn any_credential() -> Fuzzer<Credential> {
  map2(
    bool(),
    bytearray_between(28, 28),
    fn(coin_flip, key_hash) {
      if coin_flip {
        VerificationKey(key_hash)
      } else {
        Script(key_hash)
      }
    },
  )
}

pub fn any_address() -> Fuzzer<Address> {
  let address_type <- and_then(int_between(0, 5))
  when address_type is {
    0 -> {
      let payment <- map(bytearray_between(28, 28))
      Address {
        payment_credential: VerificationKey(payment),
        stake_credential: None,
      }
    }
    1 -> {
      let payment <- map(bytearray_between(28, 28))
      Address { payment_credential: Script(payment), stake_credential: None }
    }
    2 -> {
      let payment <- and_then(bytearray_between(28, 28))
      let stake <- map(bytearray_between(28, 28))
      Address {
        payment_credential: VerificationKey(payment),
        stake_credential: Some(Inline(VerificationKey(stake))),
      }
    }
    3 -> {
      let payment <- and_then(bytearray_between(28, 28))
      let stake <- map(bytearray_between(28, 28))
      Address {
        payment_credential: VerificationKey(payment),
        stake_credential: Some(Inline(Script(stake))),
      }
    }
    4 -> {
      let payment <- and_then(bytearray_between(28, 28))
      let stake <- map(bytearray_between(28, 28))
      Address {
        payment_credential: Script(payment),
        stake_credential: Some(Inline(VerificationKey(stake))),
      }
    }
    5 -> {
      let payment <- and_then(bytearray_between(28, 28))
      let stake <- map(bytearray_between(28, 28))
      Address {
        payment_credential: Script(payment),
        stake_credential: Some(Inline(Script(stake))),
      }
    }
    _ -> fail @"unexpected address type"
  }
}
