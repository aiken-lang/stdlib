// use aiken/bls12_381/fp

// use aiken/bls12_381/fp2
// use aiken/bls12_381/scalar
use aiken/builtin

pub const bls12_381_g1_generator_bytearray: ByteArray =
  #"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb"

pub const bls12_381_g2_generator_bytearray: ByteArray =
  #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8"

test add_generators_to_itself() {
  let g1 = builtin.bls12_381_g1_uncompress(bls12_381_g1_generator_bytearray)
  let g2 = builtin.bls12_381_g2_uncompress(bls12_381_g2_generator_bytearray)
  and {
    builtin.bls12_381_g1_add(g1, g1) == builtin.bls12_381_g1_scalar_mul(2, g1),
    builtin.bls12_381_g2_add(g2, g2) == builtin.bls12_381_g2_scalar_mul(2, g2),
  }
}
