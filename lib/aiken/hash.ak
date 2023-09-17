//// This module defines `Hash`, a self-documenting type-alias with a
//// phantom-type for readability.
////
//// On-chain, any hash digest value is represented as a plain 'ByteArray'.
//// Though in practice, hashes come from different sources and have
//// different semantics.
////
//// Hence, while this type-alias doesn't provide any strong type-guarantees,
//// it helps writing functions signatures with more meaningful types than mere
//// 'ByteArray'.
////
//// Compare for example:
////
//// ```aiken
//// pub type Credential {
////   VerificationKeyCredential(ByteArray)
////   ScriptCredential(ByteArray)
//// }
//// ```
////
//// with
////
//// ```aiken
//// pub type Credential {
////   VerificationKeyCredential(Hash<Blake2b_224, VerificationKey>)
////   ScriptCredential(Hash<Blake2b_224, Script>)
//// }
//// ```
////
//// Both are strictly equivalent, but the second reads much better.

use aiken/builtin

/// A `Hash` is nothing more than a `ByteArray`, but it carries extra
/// information for readability.
pub type Hash<alg, a> =
  ByteArray

/// A blake2b-224 hash algorithm.
///
/// Typically used for:
///
/// - [`Credential`](../aiken/transaction/credential.html#Credential)
/// - [`PolicyId`](../aiken/transaction/value.html#PolicyId)
///
/// Note: there's no function to calculate blake2b-224 hash digests on-chain.
pub opaque type Blake2b_224 {
  Blake2b_224
}

/// A blake2b-256 hash algorithm.
///
/// Typically used for:
///
/// - [`TransactionId`](../aiken/transaction.html#TransactionId)
pub opaque type Blake2b_256 {
  Blake2b_256
}

/// Compute the blake2b-256 hash digest of some data.
pub fn blake2b_256(data: Data) -> Hash<Blake2b_256, a> {
  hash_serialiser(builtin.blake2b_256, data)
}

/// A SHA2-256 hash algorithm.
pub opaque type Sha2_256 {
  Sha2_256
}

/// Compute the sha2-256 hash digest of some data.
pub fn sha2_256(data: Data) -> Hash<Sha2_256, a> {
  hash_serialiser(builtin.sha2_256, data)
}

/// A SHA3-256 hash algorithm.
pub opaque type Sha3_256 {
  Sha3_256
}

/// Compute the sha3-256 hash digest of some data.
pub fn sha3_256(data: Data) -> Hash<Sha3_256, a> {
  hash_serialiser(builtin.sha3_256, data)
}

fn hash_serialiser(hash_function: fn(ByteArray) -> ByteArray, data: Data) {
  let as_serialisable =
    fn() { hash_function(builtin.serialise_data(data)) }
  let as_bytestring =
    fn() {
      expect bytes: ByteArray = data
      hash_function(bytes)
    }
  builtin.choose_data(
    data,
    as_serialisable,
    as_serialisable,
    as_serialisable,
    as_serialisable,
    as_bytestring,
  )()
}
