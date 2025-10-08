use aiken/builtin.{bls12_381_final_verify, bls12_381_miller_loop}
use aiken/crypto/bitwise.{State}
use aiken/crypto/bls12_381/g1
use aiken/crypto/bls12_381/g2
use aiken/crypto/bls12_381/scalar.{Scalar}

pub fn miller_loop(q: G1Element, p: G2Element) -> MillerLoopResult {
  bls12_381_miller_loop(q, p)
}

pub fn final_exponentiation(
  left: MillerLoopResult,
  right: MillerLoopResult,
) -> Bool {
  bls12_381_final_verify(left, right)
}

test simple_miller_loop_with_final_exponentiation() {
  // prove e(q^x, p^m) == e(q^m*x, p)
  let x: State<Scalar> = scalar.from_int(44203)
  let u: G1Element = g1.generator |> g1.scale(x)
  let mb: ByteArray = #"acab"
  let m: State<Scalar> = scalar.from_bytes(mb)
  let qmx: G2Element = g2.generator |> g2.scale(x) |> g2.scale(m)
  let qm: G2Element = g2.scale(g2.generator, m)
  let left: MillerLoopResult = miller_loop(u, qm)
  let right: MillerLoopResult = miller_loop(g1.generator, qmx)
  final_exponentiation(left, right)
}
