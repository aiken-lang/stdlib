# Changelog

## v2.0.0 - UNRELEASED

### Added

- New modules covering Conway-related features (i.e. governance)
  - [`cardano/governance`](https://aiken-lang.github.io/stdlib/cardano/governance.html)
  - [`cardano/governance/protocol_parameters`](https://aiken-lang.github.io/stdlib/cardano/governance/protocol_parameters.html)

- New primitives in `aiken/crypto`:
  - [`blake2b_224`](https://aiken-lang.github.io/stdlib/aiken/crypto.html#blake2b_224)
  - [`keccak_256`](https://aiken-lang.github.io/stdlib/aiken/crypto.html#keccak_256)

- New primitives in `aiken/math`:
  - [`log2`](https://aiken-lang.github.io/stdlib/aiken/math.html#log2)

- New primitives in `aiken/primitive/bytearray`:
  - [`at`](https://aiken-lang.github.io/stdlib/aiken/primitive/bytearray.html#at)
  - [`from_int_big_endian`](https://aiken-lang.github.io/stdlib/aiken/primitive/bytearray.html#from_int_big_endian)
  - [`from_int_little_endian`](https://aiken-lang.github.io/stdlib/aiken/primitive/bytearray.html#from_int_little_endian)
  - [`to_int_big_endian`](https://aiken-lang.github.io/stdlib/aiken/primitive/bytearray.html#to_int_big_endian)
  - [`to_int_little_endian`](https://aiken-lang.github.io/stdlib/aiken/primitive/bytearray.html#to_int_little_endian)

- New primitives in `aiken/primitive/int`:
  - [`from_bytearray_big_endian`](https://aiken-lang.github.io/stdlib/aiken/primitive/int.html#from_bytearray_big_endian)
  - [`from_bytearray_little_endian`](https://aiken-lang.github.io/stdlib/aiken/primitive/int.html#from_bytearray_little_endian)

- New primitives in `aiken/crypto`:
  - [`verify_ecdsa_signature`](https://aiken-lang.github.io/stdlib/cardano/credential.html#verify_ecdsa_signature)
  - [`verify_schnorr_signature`](https://aiken-lang.github.io/stdlib/cardano/credential.html#verify_schnorr_signature)

### Changed

- Few modules have been relocated and better organized:
  - `aiken/hash` -> [`aiken/crypto`](https://aiken-lang.github.io/stdlib/aiken/crypto.html)
  - **collections**
    - `aiken/dict` -> [`aiken/collection/dict`](https://aiken-lang.github.io/stdlib/aiken/collection/dict.html)
    - `aiken/list` -> [`aiken/collection/list`](https://aiken-lang.github.io/stdlib/aiken/collection/list.html)
    - `aiken/pairs` -> [`aiken/collection/pairs`](https://aiken-lang.github.io/stdlib/aiken/collection/pairs.html)
  - **primitive**
    - `aiken/bytearray` -> [`aiken/primitive/bytearray`](https://aiken-lang.github.io/stdlib/aiken/primitive/bytearray.html)
    - `aiken/int` -> [`aiken/primitive/int`](https://aiken-lang.github.io/stdlib/aiken/primitive/int.html)
    - `aiken/string` -> [`aiken/primitive/string`](https://aiken-lang.github.io/stdlib/aiken/primitive/string.html)
  - **cardano**
    - `aiken/transaction` -> [`cardano/transaction`](https://aiken-lang.github.io/stdlib/cardano/transaction.html)
    - `aiken/transaction/certificate` -> [`cardano/certificate`](https://aiken-lang.github.io/stdlib/cardano/certificate.html)
    - `aiken/transaction/credential` -> [`cardano/address`](https://aiken-lang.github.io/stdlib/cardano/address.html) & `aiken/crypto`
    - `aiken/transaction/value` -> [`cardano/assets`](https://aiken-lang.github.io/stdlib/cardano/assets.html)

- Several zero-argument functions have been turned into top-level constants
  - `aiken/dict.new()` -> [`aiken/collection/dict.empty`](https://aiken-lang.github.io/stdlib/aiken/collection/dict.html#empty)
  - `aiken/interval.empty()` -> [`aiken/interval.empty`](https://aiken-lang.github.io/stdlib/aiken/interval.html#empty)
  - `aiken/interval.everything()` -> [`aiken/interval.everything`](https://aiken-lang.github.io/stdlib/aiken/interval.html#everything)
  - `aiken/math/rational.zero()` -> [`aiken/math/rational.zero`](https://aiken-lang.github.io/stdlib/aiken/math/rational.html#zero)
  - `aiken/transaction/value.zero()` -> [`cardano/assets.zero`](https://aiken-lang.github.io/stdlib/cardano/assets.html#zero)

- The `Transaction` type from [`cardano/transaction`](https://aiken-lang.github.io/stdlib/cardano/transaction.html) (originally `aiken/transaction`) has been greatly reworked to match the new transaction format in Plutus V3.

- The `ScriptContext` type has split from `cardano/transaction` (originally `aiken/transaction`) and moved into its own module [`cardano/script_context`](https://aiken-lang.github.io/stdlib/cardano/script_context.html) and adjusted to its new form as per Plutus V3.

- The constructors of [`Credential`](https://aiken-lang.github.io/stdlib/cardano/address.html#credential) have been renamed from `VerificationKeyCredential` and `ScriptCredential` into `VerificationKey` and `Script` respectively.

- The function `remove_all`, `remove_first` and `remove_last` from [`aiken/collection/pairs`](https://aiken-lang.github.io/stdlib/aiken/collection/pairs.html) (originally `aiken/pairs`) have been renamed to `delete_all`, `delete_first` and `delete_last` respectively.

- The function `verify_signature` from [`aiken/crypto`](https://aiken-lang.github.io/stdlib/aiken/crypto.html) (originally `aiken/credential`) has been renamed to `verify_ed25519_signature`.

### Removed

- The module `aiken/time`. The `PosixTime` alias is no longer used anywhere.

- `MintedValue` (from `aiken/transaction/value` originally) and its associated functions are no longer needed and, therefore, gone.

## v1.9.0 - 2024-05-24

### Added

- A new module [`aiken/pairs`](https://aiken-lang.github.io/stdlib/aiken/pairs.html) to work with associative lists (a.k.a. `Pairs`).

### Changed

- **BREAKING-CHANGE**<br/>
  Specialized all `Dict`'s key to `ByteArray`, and thus remove the need for passing an extra comparison function in many functions. `Dict` are however still specialized with a phantom type for keys.

- **BREAKING-CHANGE**<br/>
  Few functions from `Dict` have been renamed for consistency:
  - `from_list` -> `from_pairs`
  - `from_ascending_list` -> `from_ascending_pairs`
  - `to_list` -> `to_pairs`

### Removed

N/A

## v1.8.0 - 2024-03-28

### Added

- [`value.reduce`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#reduce) to efficiently fold over a value and its elements.

- [`value.from_asset_list`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#from_asset_list) to turn an asset list into a Value while enforcing invariants expected of `Value`.

- [`math.is_sqrt`](https://aiken-lang.github.io/stdlib/aiken/math.html#is_sqrt) as a more efficient alternative to `sqrt`.

### Changed

- Disclaimers in documentation to [`bytearray.to_string`](https://aiken-lang.github.io/stdlib/aiken/bytearray.html#to_string) and [`string.from_bytearray`](https://aiken-lang.github.io/stdlib/aiken/string.html#from_bytearray) regarding UTF-8 encoding.

### Removed

N/A

## v1.7.0 - 2023-11-07

### Added

- [`list.index_of`](https://aiken-lang.github.io/stdlib/aiken/list.html#index_of): For getting a values index in a list.
- [`transaction.placeholder`](https://aiken-lang.github.io/stdlib/aiken/transaction.html#placeholder): For constructing test transactions.
- [`transaction.value.is_zero`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#is_zero): For checking whether a value is null.

### Changed

- [`value.to_minted_value`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#to_minted_value) now correctly preserves the invariant of `MintedValue`: it always contain a null quantity of Ada.

### Removed

N/A

## v1.6.0 - 2023-09-08

### Added

- [`math.pow2`](https://aiken-lang.github.io/stdlib/aiken/math.html#pow2): For faster exponentions for powers of two.
- [`bytearray.test_bit`](https://aiken-lang.github.io/stdlib/aiken/bytearray.html#test_bit): For testing if a bit is set in a bytearray (MSB).

## v1.5.0 - 2023-08-16

### Removed

- retired `list.and` and `list.or` because of the new keywords for logical op chaining.

## v1.4.0 - 2023-07-21

### Changed

- Fixed missing null-check on `value.add`. Adding a null quantity of token is now correctly a no-op.

## v1.3.0 - 2023-06-30

### Added

- [`math.sqrt`](https://aiken-lang.github.io/stdlib/aiken/math.html#sqrt): For calculating integer square roots using a quadratically convergent method.
- [`math/rational.numerator`](https://aiken-lang.github.io/stdlib/aiken/math/rational.html#numerator) & [`math/rational.denominator`](https://aiken-lang.github.io/stdlib/aiken/math/rational.html#numerator): For accessing parts of a rational value.
- [`math/rational.arithmetic_mean`](https://aiken-lang.github.io/stdlib/aiken/math/rational.html#arithmetic_mean): For computing [arithmetic mean](https://en.wikipedia.org/wiki/Arithmetic_mean) of rational values.
- [`math/rational.geometric_mean`](https://aiken-lang.github.io/stdlib/aiken/math/rational.html#geometric_mean): For computing [geometric mean](https://en.wikipedia.org/wiki/Geometric_mean) of two rational values.

### Changed

- Clear empty asset lists in [`Value`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#Value) on various operations. Before that fix, it could happen that removing all assets from a given policy would lead to an empty dictionnary of assets still be present in the `Value`.

## v1.2.0 - 2023-06-17

### Added

- [`transaction/value.MintedValue`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#MintedValue)
- [`transaction/value.from_minted_value`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#from_minted_value): Convert from `MintedValue` to `Value`
- [`transaction/value.to_minted_value`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#to_minted_value): Convert from `Value` to `MintedValue`
- [`transaction/bytearray.to_hex`](https://aiken-lang.github.io/stdlib/aiken/bytearray.html#to_hex): Convert a `ByteArray` to a hex encoded `String`
- [`math/rational`](https://aiken-lang.github.io/stdlib/aiken/math/rational.html): Working with rational numbers.
  - [x] `abs`
  - [x] `add`
  - [x] `ceil`
  - [x] `compare`
  - [x] `compare_with`
  - [x] `div`
  - [x] `floor`
  - [x] `from_int`
  - [x] `mul`
  - [x] `negate`
  - [x] `new`
  - [x] `proper_fraction`
  - [x] `reciprocal`
  - [x] `reduce`
  - [x] `round`
  - [x] `round_even`
  - [x] `sub`
  - [x] `truncate`
  - [x] `zero`

### Removed

- module `MintedValue` was merged with `Value`

## v1.1.0 - 2023-06-06

### Added

- [`list.count`](https://aiken-lang.github.io/stdlib/aiken/list.html#count): Count how many items in the list satisfy the given predicate.

- [`int.from_utf8`](https://aiken-lang.github.io/stdlib/aiken/int.html#from_utf8): Parse an integer from a utf-8 encoded `ByteArray`, when possible.

- [`dict.foldl`](https://aiken-lang.github.io/stdlib/aiken/dict.html#foldl) & [`dict.foldr`](https://aiken-lang.github.io/stdlib/aiken/dict.html#foldr): for left and right folds over dictionnary elements in ascending key order.

- [`dict.insert_with`](https://aiken-lang.github.io/stdlib/aiken/dict.html#insert_with): Insert a value in the dictionary at a given key. When the key already exist, the provided merge function is called.

- [`transaction/value.add`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#add): Add a (positive or negative) quantity of a single token to a value. This is more efficient than `merge` for a single asset.

- [`transaction/value.to_dict`](https://aiken-lang.github.io/stdlib/aiken/transaction/value.html#to_dict): Convert a `Value` into a dictionnary of dictionnaries.

- A new module [`transaction/minted_value`](https://aiken-lang.github.io/stdlib/aiken/transaction/minted_value.html): This is used exclusively for representing values present in the `mint` field of transactions. This allows to simplify some of the implementation for `Value` which no longer needs to handle the special case where null-quantity tokens would be present. It isn't possible to construct `MintedValue` by hand, they come from the script context entirely and are 'read-only'.

- More documentation for `dict` and `interval` modules.

### Changed

> **Warning**
>
> Most of those changes are breaking-changes. Though, given we're still in an
> alpha state, only the `minor` component is bumped from the version number.
> Please forgive us.

- Rework `list.{foldl, foldr, reduce, indexed_foldr}`, `dict.{fold}`, `bytearray.{foldl, foldr, reduce}` to take the iterator as last argument. For example:

  ```
  fn foldl(self: List<a>, with: fn(a, b) -> b, zero: b) -> b

  ↓ becomes

  fn foldl(self: List<a>, zero: b, with: fn(a, b) -> b) -> b
  ```

- Fixed implementation of `bytearray.slice`; `slice` would otherwise behave as if the second argument were an offset.

- Rename `transaction/value.add` into `transaction/value.merge`.

- Swap arguments of the merge function in `dict.union_with`; the first value received now corresponds to the value already present in the dictionnary.

- Fixed various examples from the documentation

### Removed

- Removed `dict.fold`; replaced with `dict.foldl` and `dict.foldr` to remove ambiguity.

## v1.0.0 - 2023-04-13

### Added

N/A

### Changed

N/A

### Removed

N/A
