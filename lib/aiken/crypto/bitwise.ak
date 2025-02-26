use aiken/builtin

pub opaque type State<t> {
  inner: Int,
}

pub const zero_intermediary = State { inner: 0 }

pub const one_intermediary = State { inner: 1 }

pub fn add_bits(scalar: Int, big_endian: Bool) {
  fn(intermediate: State<t>, bytes: ByteArray) -> State<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.add_integer(intermediate.inner)
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn add_int(scalar: Int) {
  fn(intermediate: State<t>, int: Int) -> State<t> {
    intermediate.inner + int
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn add_intermediary(scalar: Int) {
  fn(intermediate: State<t>, other: State<t>) -> State<t> {
    intermediate.inner + other.inner
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn sub_bits(scalar: Int, big_endian: Bool) {
  fn(intermediate: State<t>, bytes: ByteArray) -> State<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.subtract_integer(intermediate.inner)
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn sub_int(scalar: Int) {
  fn(intermediate: State<t>, int: Int) -> State<t> {
    intermediate.inner - int
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn sub_intermediary(scalar: Int) {
  fn(intermediate: State<t>, other: State<t>) -> State<t> {
    intermediate.inner - other.inner
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn mul_bits(scalar: Int, big_endian: Bool) {
  fn(intermediate: State<t>, bytes: ByteArray) -> State<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.multiply_integer(intermediate.inner)
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn mul_int(scalar: Int) {
  fn(intermediate: State<t>, int: Int) -> State<t> {
    intermediate.inner * int
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn mul_intermediary(scalar: Int) {
  fn(intermediate: State<t>, other: State<t>) -> State<t> {
    intermediate.inner * other.inner
      |> builtin.mod_integer(scalar)
      |> State
  }
}

pub fn scale(self: State<t>, e: Int, scalar: Int) -> State<t> {
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
  fn(self: State<t>, k: Int) -> State<t> {
    if k == 0 {
      self
    } else {
      do_scale2(mul_intermediary(scalar)(self, self), k - 1, scalar)
    }
  }
}

fn do_scale2(self: State<t>, k: Int, scalar) -> State<t> {
  if k == 0 {
    self
  } else {
    do_scale2(mul_intermediary(scalar)(self, self), k - 1, scalar)
  }
}

pub fn neg(scalar: Int) {
  fn(intermediate: State<t>) -> State<t> {
    scalar - intermediate.inner
      |> State
  }
}

pub fn to_int(intermediate: State<t>) -> Int {
  intermediate.inner
}

pub fn from_int(int: Int, field: Int) -> State<t> {
  int % field
    |> State
}
