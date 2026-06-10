use aiken/crypto/bitwise.{State}
use aiken/crypto/bls12_381.{domain_separation_tag_nul}
use aiken/crypto/bls12_381/g1
use aiken/crypto/bls12_381/g2
use aiken/crypto/bls12_381/pairing.{final_exponentiation, miller_loop, mul}
use aiken/crypto/bls12_381/scalar.{Scalar}

// -------------------------------- simple_miller_loop_with_final_exponentiation

// prove: e(q^x, p^m) == e(q, p^m*x)
test simple_miller_loop_with_final_exponentiation() {
  let secret: State<Scalar> = scalar.from_int(44203)

  let public_value: G1Element = g1.generator |> g1.scale(secret)

  let message: ByteArray = #"acab"

  let challenge: G2Element = message
    |> g2.hash_to_group(domain_separation_tag_nul)

  let witness: G2Element = message
    |> g2.hash_to_group(domain_separation_tag_nul)
    |> g2.scale(secret)

  final_exponentiation(
    miller_loop(public_value, challenge),
    miller_loop(g1.generator, witness),
  )
}

// ------------------------------------------------------------------------- mul

// prove bilinearity via aggregation: e(p, q) * e(p, q) == e(2p, q)
test mul_aggregates_pairings() {
  let two: State<Scalar> = scalar.from_int(2)

  let double_generator: G1Element = g1.generator |> g1.scale(two)

  final_exponentiation(
    mul(
      miller_loop(g1.generator, g2.generator),
      miller_loop(g1.generator, g2.generator),
    ),
    miller_loop(double_generator, g2.generator),
  )
}

// prove bilinearity in the second argument: e(p, q) * e(p, q') == e(p, q + q')
test mul_bilinear_in_second_argument() {
  let p: G1Element = g1.generator
  let q: G2Element = g2.generator
  let q2: G2Element = #"face" |> g2.hash_to_group(domain_separation_tag_nul)

  final_exponentiation(
    mul(miller_loop(p, q), miller_loop(p, q2)),
    miller_loop(p, g2.add(q, q2)),
  )
}
