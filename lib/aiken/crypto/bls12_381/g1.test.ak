use aiken/builtin
use aiken/crypto/bls12_381/g1.{
  add, compress, equal, generator, hash_to_group, neg, scale, sub, zero,
}
use aiken/crypto/bls12_381/scalar

// -------------------------------------------------------------------- compress

test compress_1() {
  compress(
    #<Bls12_381, G1>"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
  ) == #"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb"
}

// ----------------------------------------------------------------------- equal

test equal_1() {
  equal(generator, generator)
}

// ------------------------------------------------------------------------- neg

test neg_1() {
  // A point added to its negation yields the identity (zero) point.
  add(generator, neg(generator)) == zero
}

test neg_2() {
  // Negation matches subtraction from the identity (zero) point.
  neg(generator) == sub(zero, generator)
}

// ------------------------------------------------------------------------- sub

test sub_1() {
  generator == sub(add(generator, generator), generator)
}

test sub_2() {
  // A point subtracted from itself yields the identity (zero) point.
  sub(generator, generator) == zero
}

// ----------------------------------------------------------------------- scale

test scale_1() {
  let x = scalar.from_int(2)
  builtin.bls12_381_g1_add(generator, generator) == scale(generator, x)
}

// --------------------------------------------------------------- hash_to_group

test hash_to_group_1() {
  hash_to_group("hello", "world") == #<Bls12_381, G1>"89223b03c629cc6bcbbdccbba46b6679bc6a79db82f2d3bd115899a45a5a38c391587b59d3d1e297f977d1c4ee9e3388"
}

// ------------------------------------------------------------------- generator

test generator_1() {
  builtin.bls12_381_g1_scalar_mul(scalar.field_prime, generator) == #<Bls12_381, G1>"c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
}

// ------------------------------------------------------------------------ zero

test zero_1() {
  and {
    zero == builtin.bls12_381_g1_scalar_mul(scalar.field_prime, generator),
    zero == builtin.bls12_381_g1_scalar_mul(
      scalar.field_prime,
      #<Bls12_381, G1>"88c7e388ee58f1db9a24d7098b01d13634298bebf2d159254975bd450cb0d287fcc622eb71edde8b469a8513551baf1f",
    ),
    zero == builtin.bls12_381_g1_scalar_mul(
      scalar.field_prime,
      #<Bls12_381, G1>"a6ac32e625dc30b8d31bacf5f4c89c27b0388b15f57ae10de8d5cec02dd1f113c9a31077be05ab587ca57a88d34deb75",
    ),
  }
}
