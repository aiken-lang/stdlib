use aiken/builtin.{bls12_381_final_verify, bls12_381_miller_loop}
use aiken/crypto/bitwise.{State}
use aiken/crypto/bls12_381/g1
use aiken/crypto/bls12_381/g2
use aiken/crypto/bls12_381/scalar.{Scalar}

/// Computes a MillerLoop over the elements `q` and `p`
pub fn miller_loop(q: G1Element, p: G2Element) -> MillerLoopResult {
  bls12_381_miller_loop(q, p)
}

/// Final exponentiation against two `MillerLoopResult`.
///
/// ```aiken
/// prove: e(q^x, p^m) == e(q, p^m*x)
/// let secret: State<Scalar> = scalar.from_int(44203)
///
/// let public_value: G1Element = g1.generator |> g1.scale(secret)
///
/// let message: ByteArray = #"acab"
///
/// let challenge: G2Element =
///   message |> g2.hash_to_group(g2.domain_separation_tag_basic)
///
/// let witness: G2Element =
///   message
///     |> g2.hash_to_group(g2.domain_separation_tag_basic)
///     |> g2.scale(secret)
///
/// final_exponentiation(
///   miller_loop(public_value, challenge),
///   miller_loop(g1.generator, witness),
/// )
/// ```
pub fn final_exponentiation(
  left: MillerLoopResult,
  right: MillerLoopResult,
) -> Bool {
  bls12_381_final_verify(left, right)
}

// prove: e(q^x, p^m) == e(q, p^m*x)
test simple_miller_loop_with_final_exponentiation() {
  let secret: State<Scalar> = scalar.from_int(44203)

  let public_value: G1Element = g1.generator |> g1.scale(secret)

  let message: ByteArray = #"acab"

  let challenge: G2Element =
    message |> g2.hash_to_group(g2.domain_separation_tag_basic)

  let witness: G2Element =
    message
      |> g2.hash_to_group(g2.domain_separation_tag_basic)
      |> g2.scale(secret)

  final_exponentiation(
    miller_loop(public_value, challenge),
    miller_loop(g1.generator, witness),
  )
}
