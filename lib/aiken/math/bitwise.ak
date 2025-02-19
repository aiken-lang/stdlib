use aiken/builtin

pub opaque type Intermediary<t> {
  inner: Int,
}

pub const zero_intermediary = Intermediary { inner: 0 }

pub const one_intermediary = Intermediary { inner: 1 }

pub opaque type Scalar {
  inner: Int,
}

pub fn from_scalar(scalar: Scalar) -> Intermediary<t> {
  Intermediary { inner: scalar.inner }
}

pub fn add_bits(scalar: Int, big_endian: Bool) {
  fn(intermediate: Intermediary<t>, bytes: ByteArray) -> Intermediary<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.add_integer(intermediate.inner)
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn add_int(scalar: Int) {
  fn(intermediate: Intermediary<t>, int: Int) -> Intermediary<t> {
    intermediate.inner + int
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn add_intermediary(scalar: Int) {
  fn(intermediate: Intermediary<t>, other: Intermediary<t>) -> Intermediary<t> {
    intermediate.inner + other.inner
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn sub_bits(scalar: Int, big_endian: Bool) {
  fn(intermediate: Intermediary<t>, bytes: ByteArray) -> Intermediary<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.subtract_integer(intermediate.inner)
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn sub_int(scalar: Int) {
  fn(intermediate: Intermediary<t>, int: Int) -> Intermediary<t> {
    intermediate.inner - int
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn sub_intermediary(scalar: Int) {
  fn(intermediate: Intermediary<t>, other: Intermediary<t>) -> Intermediary<t> {
    intermediate.inner - other.inner
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn mul_bits(scalar: Int, big_endian: Bool) {
  fn(intermediate: Intermediary<t>, bytes: ByteArray) -> Intermediary<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.multiply_integer(intermediate.inner)
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn mul_int(scalar: Int) {
  fn(intermediate: Intermediary<t>, int: Int) -> Intermediary<t> {
    intermediate.inner * int
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn mul_intermediary(scalar: Int) {
  fn(intermediate: Intermediary<t>, other: Intermediary<t>) -> Intermediary<t> {
    intermediate.inner * other.inner
      |> builtin.mod_integer(scalar)
      |> Intermediary
  }
}

pub fn scale(self: Intermediary<t>, e: Int, scalar: Int) -> Intermediary<t> {
  if e < 0 {
    zero_intermediary
  } else if e == 0 {
    one_intermediary
  } else if e % 2 == 0 {
    scale(mul_intermediary(scalar)(self, self), e / 2, scalar)
  } else {
    mul_intermediary(scalar)(
      self,
      scale(mul_intermediary(scalar)(self, self), ( e - 1 ) / 2, scalar),
    )
  }
}

/// A faster version of `scale` for the case where the exponent is a power of two.
/// That is, the exponent `e = 2^k` for some non-negative integer `k`. Which is used alot in zk-SNARKs.
pub fn scale2(scalar: Int) {
  fn(self: Intermediary<t>, k: Int) -> Intermediary<t> {
    if k == 0 {
      self
    } else {
      do_scale2(mul_intermediary(scalar)(self, self), k - 1, scalar)
    }
  }
}

fn do_scale2(self: Intermediary<t>, k: Int, scalar) -> Intermediary<t> {
  if k == 0 {
    self
  } else {
    do_scale2(mul_intermediary(scalar)(self, self), k - 1, scalar)
  }
}

pub fn neg(scalar: Int) {
  fn(intermediate: Intermediary<t>) -> Intermediary<t> {
    scalar - intermediate.inner
      |> Intermediary
  }
}

pub opaque type Hash256 {
  inner: ByteArray,
}

pub const hash256_field =
  builtin.replicate_byte(32, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

pub const hash224_field =
  builtin.replicate_byte(28, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

/// The prime number defining the scalar field of the BLS12-381 curve.
pub const bls381_prime_field =
  52435875175126190479447740508185965837690552500527637822603658699938581184513

pub fn to_bits256(intermediate: Intermediary<Hash256>) -> ByteArray {
  intermediate.inner
    |> builtin.integer_to_bytearray(True, 32, _)
}

pub fn to_int256(intermediate: Intermediary<Hash256>) -> Int {
  intermediate.inner
}

pub fn bits256_to_intermediary(bytes: ByteArray) -> Intermediary<Hash256> {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> builtin.mod_integer(hash256_field)
    |> Intermediary
}

pub fn int256_to_intermediary(int: Int) -> Intermediary<Hash256> {
  int % hash256_field
    |> Intermediary
}

pub fn add_bits256(
  intermediate: Intermediary<Hash256>,
  bytes: ByteArray,
) -> Intermediary<Hash256> {
  let add_bits = add_bits(hash256_field, True)

  add_bits(intermediate, bytes)
}

pub fn add_int256(
  intermediate: Intermediary<Hash256>,
  int: Int,
) -> Intermediary<Hash256> {
  let add_int = add_int(hash256_field)

  add_int(intermediate, int)
}

pub fn sub_int256(
  intermediate: Intermediary<Hash256>,
  int: Int,
) -> Intermediary<Hash256> {
  let sub_int = sub_int(hash256_field)

  sub_int(intermediate, int)
}

pub fn sub_bits256(
  intermediate: Intermediary<Hash256>,
  bytes: ByteArray,
) -> Intermediary<Hash256> {
  let sub_bits = sub_bits(hash256_field, True)

  sub_bits(intermediate, bytes)
}

pub fn mul_bits256(
  intermediate: Intermediary<Hash256>,
  bytes: ByteArray,
) -> Intermediary<Hash256> {
  let mul_bits = mul_bits(hash256_field, True)

  mul_bits(intermediate, bytes)
}

pub fn mul_int256(
  intermediate: Intermediary<Hash256>,
  int: Int,
) -> Intermediary<Hash256> {
  let mul_int = mul_int(hash256_field)

  mul_int(intermediate, int)
}

pub fn neg_256(intermediate: Intermediary<Hash256>) -> Intermediary<Hash256> {
  let neg = neg(hash256_field)

  neg(intermediate)
}

pub opaque type Hash224 {
  inner: ByteArray,
}

pub fn to_bits224(intermediate: Intermediary<Hash224>) -> ByteArray {
  intermediate.inner
    |> builtin.integer_to_bytearray(True, 28, _)
}

pub fn to_int224(intermediate: Intermediary<Hash224>) -> Int {
  intermediate.inner
}

pub fn bits224_to_intermediary(bytes: ByteArray) -> Intermediary<Hash224> {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> builtin.mod_integer(hash224_field)
    |> Intermediary
}

pub fn int224_to_intermediary(int: Int) -> Intermediary<Hash224> {
  int % hash256_field
    |> Intermediary
}
