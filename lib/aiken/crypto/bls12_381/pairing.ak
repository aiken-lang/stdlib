use aiken/builtin.{
  bls12_381_final_verify, bls12_381_miller_loop,
  bls12_381_mul_miller_loop_result,
}

/// Computes a MillerLoop over the elements `q` and `p`
pub fn miller_loop(q: G1Element, p: G2Element) -> MillerLoopResult {
  bls12_381_miller_loop(q, p)
}

/// Multiplies two `MillerLoopResult` together.
///
/// This aggregates several pairings into a single `MillerLoopResult` before a
/// final verification, relying on the bilinearity of the pairing `e`:
///
/// ```aiken
/// // e(q1, p1) * e(q2, p2)
/// mul(miller_loop(q1, p1), miller_loop(q2, p2))
/// ```
pub fn mul(left: MillerLoopResult, right: MillerLoopResult) -> MillerLoopResult {
  bls12_381_mul_miller_loop_result(left, right)
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
///   message |> g2.hash_to_group(domain_separation_tag_nul)
///
/// let witness: G2Element =
///   message
///     |> g2.hash_to_group(domain_separation_tag_nul)
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
