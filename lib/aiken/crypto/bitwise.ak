//// @hidden

use aiken/builtin

pub opaque type State<t> {
  inner: Int,
}

pub const zero = State { inner: 0 }

pub const one = State { inner: 1 }

pub fn add_bits(field: Int, big_endian: Bool) {
  fn(state: State<t>, bytes: ByteArray) -> State<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.add_integer(state.inner, _)
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn add_int(field: Int) {
  fn(state: State<t>, int: Int) -> State<t> {
    state.inner + int
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn add_state(field: Int) {
  fn(state: State<t>, other: State<t>) -> State<t> {
    state.inner + other.inner
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn sub_bits(field: Int, big_endian: Bool) {
  fn(state: State<t>, bytes: ByteArray) -> State<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.subtract_integer(state.inner, _)
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn sub_int(field: Int) {
  fn(state: State<t>, int: Int) -> State<t> {
    state.inner - int
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn sub_state(field: Int) {
  fn(state: State<t>, other: State<t>) -> State<t> {
    state.inner - other.inner
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn mul_bits(field: Int, big_endian: Bool) {
  fn(state: State<t>, bytes: ByteArray) -> State<t> {
    builtin.bytearray_to_integer(big_endian, bytes)
      |> builtin.multiply_integer(state.inner, _)
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn mul_int(field: Int) {
  fn(state: State<t>, int: Int) -> State<t> {
    state.inner * int
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn mul_state(field: Int) {
  fn(state: State<t>, other: State<t>) -> State<t> {
    state.inner * other.inner
      |> builtin.mod_integer(field)
      |> State
  }
}

pub fn scale(
  self: State<t>,
  e: Int,
  mul: fn(State<t>, State<t>) -> State<t>,
) -> State<t> {
  if e < 0 {
    zero
  } else if e == 0 {
    one
  } else if e % 2 == 0 {
    scale(mul(self, self), e / 2, mul)
  } else {
    mul(self, scale(mul(self, self), ( e - 1 ) / 2, mul))
  }
}

/// A faster version of `scale` for the case where the exponent is a power of two.
/// That is, the exponent $e = 2^k$ for some non-negative integer $k$. Which is used a lot in zk-SNARKs.
pub fn scale2(self: State<t>, k: Int, mul: fn(State<t>, State<t>) -> State<t>) {
  if k < 0 {
    zero
  } else {
    do_scale2(self, k, mul)
  }
}

fn do_scale2(self: State<t>, k: Int, mul) -> State<t> {
  if k == 0 {
    self
  } else {
    do_scale2(mul(self, self), k - 1, mul)
  }
}

pub fn neg(field: Int) {
  fn(state: State<t>) -> State<t> {
    ( field - state.inner ) % field
      |> State
  }
}

pub fn to_int(state: State<t>) -> Int {
  state.inner
}

pub fn from_int(int: Int, field: Int) -> State<t> {
  int % field
    |> State
}
