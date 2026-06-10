use aiken/builtin
use aiken/crypto/bls12_381/g2.{
  add, compress, equal, generator, hash_to_group, neg, scale, sub, zero,
}
use aiken/crypto/bls12_381/scalar

// -------------------------------------------------------------------- compress

test compress_1() {
  let g2 = #<Bls12_381, G2>"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8"
  compress(g2) == #"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8"
}

// ------------------------------------------------------------------ decompress

test decompress_1() {
  let g2 = #<Bls12_381, G2>"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8"
  generator == g2
}

// ----------------------------------------------------------------------- equal

test equal_1() {
  equal(
    generator,
    #<Bls12_381, G2>"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8",
  )
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
  builtin.bls12_381_g2_add(generator, generator) == scale(generator, x)
}

// --------------------------------------------------------------- hash_to_group

test hash_to_group_1() {
  hash_to_group("hello", "world") == #<Bls12_381, G2>"a18486bba1dc8321f4998ed4268c6df8dfa5618dd5c91595844059d517f8104bf8031d3e766f9c99db1d6f58b201ee9614de92fc08f9e5cc3a6cd814e871857cb6e3924e8a4fa48775116c5f158d58ceda63614d62f6b7bc47db798d656969a5"
}

// ------------------------------------------------------------------- generator

test generator_1() {
  builtin.bls12_381_g2_scalar_mul(scalar.field_prime, generator) == #<Bls12_381, G2>"c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
}

// ------------------------------------------------------------------------ zero

test zero_1() {
  and {
    zero == builtin.bls12_381_g2_scalar_mul(scalar.field_prime, generator),
    zero == builtin.bls12_381_g2_scalar_mul(
      scalar.field_prime,
      #<Bls12_381, G2>"9964a9ac2ee28a4dab595ff0970d446373bf46701c5d0b29ce8e1ba995d811a1c7b193c928269192c64ba1fbe4b1940207c251e086b452b920bc72e3cebab46ce672b9b088ca620a471d3b888d9737f6abd165319aa457dbf8835e3d34196051",
    ),
    zero == builtin.bls12_381_g2_scalar_mul(
      scalar.field_prime,
      #<Bls12_381, G2>"a900e25cb53cf1eeb1a82c0c83292937c49c97966351273767a204256a7ef6e95aa391404387075d361e7b13ccd694db03aa73ee0e1bd2c3dd735582b99fdf71696de72e4eda18ae99ea45995f1c9605aa0057008ee9a4da604b5716fb4a345b",
    ),
  }
}
