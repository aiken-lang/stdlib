# Aiken Standard Library

The official standard library for the [Aiken](https://aiken-lang.org) Cardano
smart-contract language.

It extends the language builtins with useful data-types, functions, constants
and aliases that make using Aiken a bliss.

```aiken
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext}
use aiken/transaction/credential.{VerificationKey}

pub type Datum {
  owner: Hash<Blake2b_224, VerificationKey>,
}

pub type Redeemer {
  msg: ByteArray,
}

/// A simple validator which replicates a basic public/private signature lock.
///
/// - The key (hash) is set as datum when the funds are sent to the script address.
/// - The spender is expected to provide a signature, and the string 'Hello, World!' as message
/// - The signature is implicitly verified by the ledger, and included as 'extra_signatories'
///
validator {
  fn spend(datum: Datum, redeemer: Redeemer, context: ScriptContext) -> Bool {
    let must_say_hello =
      redeemer.msg == "Hello, World!"

    let must_be_signed =
      context.transaction.extra_signatories
        |> list.any(fn(vkh: ByteArray) { vkh == datum.owner })

    must_say_hello && must_be_signed
  }
}
```
