# Aiken Standard Library

The official standard library for the [Aiken](https://aiken-lang.org) Cardano
smart-contract language.

It extends the language builtins with useful data-types, functions, constants
and aliases that make using Aiken a bliss.

```aiken
use aiken/transaction.{ScriptContext}
use aiken/transaction/credential.{Signature, VerificationKey}

// A simple validator which replicates a basic public/private signature lock.
///
/// - The key is set as datum when the funds are sent to the script address.
/// - The spender is expected to provide a signature of the transaction as a redeemer
/// - The signature is done on the whole serialized transaction body hash digest;
///   or put simply the transaction id.
pub fn spend(
  datum: VerificationKey,
  redeemer: Signature,
  context: ScriptContext,
) -> Bool {
  credential.verify_signature(datum, context.transaction.id.hash, redeemer)
}
```
