//// This module is designed for cryptographic operations involving the BLS12-381 elliptic curve, particularly focusing on the G2 group of the curve.
////
//// The key functionalities provided by this module include:
//// - Defining the generator of the G2 group, which is a fixed base point on the elliptic curve used for various cryptographic computations.
//// - Implementing the additive identity (zero) in the G2 group, which plays a crucial role in elliptic curve arithmetic.
//// - Providing functions to compress and decompress points in the G2 group. Compression reduces the size of the point representation, which is useful for efficient storage and transmission. Decompression restores the original point from its compressed form.
//// - Implementing basic arithmetic operations on the points in the G2 group, such as addition and subtraction.
//// - Enabling the exponentiation of a point in the G2 group with a scalar, which is a fundamental operation in elliptic curve cryptography.
//// - Offering a function to hash arbitrary data to a point in the G2 group, a process important in several cryptographic protocols.
////
//// This module ensures that all operations respect the properties of the BLS12-381 curve and the mathematical structure of the G2 group.

use aiken/builtin
use aiken/crypto/bitwise.{State}
use aiken/crypto/bls12_381.{DomainSeparationTag}
use aiken/crypto/bls12_381/scalar.{Scalar}

/// Domain separation tag for the basic BLS scheme, as defined in:
/// <https://www.ietf.org/archive/id/draft-irtf-cfrg-bls-signature-05.html#name-basic>
///
/// > [!CAUTION]
/// > **DEPRECATED**: use [`aiken/crypto/bls12_381.{domain_separation_tag_nul}`](../bls12_381.html#domain_separation_tag_nul) instead.
pub const domain_separation_tag_basic: DomainSeparationTag =
  "BLS_SIG_BLS12381G1_XMD:SHA-256_SSWU_RO_NUL_"

/// The compressed generator of the G2 group of the BLS12-381 curve.
/// This constant represents a fixed base point on the elliptic curve.
/// Note that flat encoded plutus does not allow for the direct usage of BLS12-381 points.
/// More explicit, any points in plutus data or scripts must be decompressed before usage onchain.
pub const generator: G2Element =
  #<Bls12_381, G2>"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8"

/// Represents the additive identity (zero) in the G2 group.
/// Note that flat encoded plutus does not allow for the direct usage of BLS12-381 points.
/// More explicit, any points in plutus data or scripts must be decompressed before usage onchain.
pub const zero: G2Element =
  #<Bls12_381, G2>"c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

/// Compresses a point in the G2 group into a more compact representation.
/// The compressed representation is the concatenation of two 48-byte strings, corresponding to a modified and complexified `x` coordinate.
/// The leading most significant 3 bits of this string indicate how to reconstruct the `y` coordinate.
///
/// > [!NOTE]
/// > More explicitly via [Zcash's spec](https://github.com/supranational/blst#serialization-format):
/// >
/// > <i>The most-significant three bits of a G1 or G2 encoding should be masked away before the coordinate(s) are interpreted. These bits are used to unambiguously represent the underlying element:
/// >
/// > - The most significant bit, when set, indicates that the point is in compressed form. Otherwise, the point is in uncompressed form.
/// > - The second-most significant bit indicates that the point is at infinity. If this bit is set, the remaining bits of the group element's encoding should be set to zero.
/// > - The third-most significant bit is set if (and only if) this point is in compressed form and it is not the point at infinity and its y-coordinate is the lexicographically largest of the two associated with the encoded x-coordinate.</i>
pub fn compress(point: G2Element) -> ByteArray {
  builtin.bls12_381_g2_compress(point)
}

/// Decompresses a point in the G2 group from its compressed form.
pub fn decompress(bytes: ByteArray) -> G2Element {
  builtin.bls12_381_g2_uncompress(bytes)
}

pub fn equal(left: G2Element, right: G2Element) {
  builtin.bls12_381_g2_equal(left, right)
}

/// Adds two points in the G2 group.
pub fn add(left: G2Element, right: G2Element) {
  builtin.bls12_381_g2_add(left, right)
}

/// Negates a point in the G2 group, returning its additive inverse.
/// That is, `add(point, neg(point))` yields the [`zero`](#zero) point.
pub fn neg(point: G2Element) -> G2Element {
  builtin.bls12_381_g2_neg(point)
}

/// Subtracts one point in the G2 group from another.
pub fn sub(left: G2Element, right: G2Element) {
  add(left, neg(right))
}

/// Exponentiates a point in the G2 group with a `scalar`.
/// This operation is equivalent to the repeated addition of the point with itself `e` times.
pub fn scale(point: G2Element, e: State<Scalar>) {
  builtin.bls12_381_g2_scalar_mul(scalar.to_int(e), point)
}

/// Hashes arbitrary data to a point in the G2 group.
/// You can use the `domain_separation_tag` parameter to cryptographically separate different uses of the hash function between applications.
///
/// See also the following [`DomainSeparationTag`](../bls12_381.html#DomainSeparationTag):
///
/// - [basic](../bls12_381.html#domain_separation_tag_nul)
/// - [augmented](../bls12_381.html#domain_separation_tag_aug)
/// - [proof of possession](../bls12_381.html#domain_separation_tag_pop)
pub fn hash_to_group(
  bytes: ByteArray,
  domain_separation_tag: DomainSeparationTag,
) {
  builtin.bls12_381_g2_hash_to_group(bytes, domain_separation_tag)
}
