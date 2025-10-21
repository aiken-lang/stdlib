<div align="center">
  <hr />
    <h2 align="center" style="border-bottom: none"><img style="position: relative; top: 0.25rem;" src="https://raw.githubusercontent.com/aiken-lang/branding/main/assets/icon.png" alt="Aiken" height="30" /> Aiken Standard Library</h2>

[![Licence](https://img.shields.io/github/license/aiken-lang/stdlib?style=for-the-badge)](https://github.com/aiken-lang/stdlib/blob/main/LICENSE)
[![Continuous Integration](https://img.shields.io/github/actions/workflow/status/aiken-lang/stdlib/continuous-integration.yml?style=for-the-badge)](https://github.com/aiken-lang/stdlib/actions/workflows/continuous-integration.yml)

  <hr/>
</div>

## Getting started

```
aiken add aiken-lang/stdlib --version v3
```

## Compatibility

stdlib's version(s)                                                 | aiken's version                  | Plutus version
---                                                                 | ---                              | ---
[`>= 3.0.0`](https://aiken-lang.github.io/stdlib/v3.0.0)            | `>= v1.1.17`                     | `V3`
[`>= 2.1.0 && < 3.0.0`](https://aiken-lang.github.io/stdlib/v2.1.0) | `>= v1.1.3`                      | `V3`
[`>= 2.0.0 && < 2.1.0`](https://aiken-lang.github.io/stdlib/v2.0.0) | `v1.1.1`, `v1.1.2`               | `V3`
[`>= 1.9.0 && < 2.0.0`](https://aiken-lang.github.io/stdlib/v1.9.0) | `v1.0.28-alpha`, `v1.0.29-alpha` | `V2`

## Overview

The official standard library for the [Aiken](https://aiken-lang.org) Cardano
smart-contract language.

It extends the language builtins with useful data-types, functions, constants
and aliases that make using Aiken a bliss.

```aiken
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{OutputReference, Transaction}

pub type Datum {
  owner: VerificationKeyHash,
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
validator hello_world {
  spend(datum: Option<Datum>, redeemer: Redeemer, _, self: Transaction) {
    expect Some(Datum { owner }) = datum

    let must_say_hello = redeemer.msg == "Hello, World!"

    let must_be_signed = list.has(self.extra_signatories, owner)

    and {
      must_say_hello,
      must_be_signed,
    }
  }
}
```

## Stats

![Alt](https://repobeats.axiom.co/api/embed/f0a17e7f6133630e165b9e56ec5447bef32fe831.svg "Repobeats analytics image")
