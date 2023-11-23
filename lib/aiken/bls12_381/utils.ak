// use aiken/bls12_381/fp
// use aiken/bls12_381/fp2
// use aiken/bls12_381/scalar
use aiken/builtin

const bls12_381_G1_generator: ByteArray =
  #"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb"

test f() {
  let g = builtin.bls12_381_g1_uncompress(bls12_381_G1_generator)
  builtin.bls12_381_g1_add(g, g) == builtin.bls12_381_g1_scalar_mul(2, g)
}
