use aiken/builtin
use aiken/crypto/bitwise.{
  State, add_bits as addbit, add_int as addint, mul_bits as mulbit,
  mul_int as mulint, neg as negbit, sub_bits as subbit, sub_int as subint,
}

pub type Hash256 =
  ByteArray

pub const hash256_field =
  builtin.replicate_byte(32, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

pub fn to_bytes(intermediate: State<Hash256>) -> ByteArray {
  bitwise.to_int(intermediate)
    |> builtin.integer_to_bytearray(True, 32, _)
}

pub fn to_int(intermediate: State<Hash256>) -> Int {
  bitwise.to_int(intermediate)
}

pub fn from_bytes(bytes: Hash256) -> State<Hash256> {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> bitwise.from_int(hash256_field)
}

pub fn from_int(int: Int) -> State<Hash256> {
  bitwise.from_int(int, hash256_field)
}

type Bitwise256Bytes =
  fn(State<Hash256>, ByteArray) -> State<Hash256>

type Bitwise256Int =
  fn(State<Hash256>, Int) -> State<Hash256>

const add_bit256: Bitwise256Bytes = addbit(hash256_field, True)

pub fn add_bytes(
  intermediate: State<Hash256>,
  bytes: ByteArray,
) -> State<Hash256> {
  add_bit256(intermediate, bytes)
}

const add_i256: Bitwise256Int = addint(hash256_field)

pub fn add_int(intermediate: State<Hash256>, int: Int) -> State<Hash256> {
  add_i256(intermediate, int)
}

const sub_i256: Bitwise256Int = subint(hash256_field)

pub fn sub_int(intermediate: State<Hash256>, int: Int) -> State<Hash256> {
  sub_i256(intermediate, int)
}

const sub_bit256: Bitwise256Bytes = subbit(hash256_field, True)

pub fn sub_bytes(
  intermediate: State<Hash256>,
  bytes: ByteArray,
) -> State<Hash256> {
  sub_bit256(intermediate, bytes)
}

const mul_bit256: Bitwise256Bytes = mulbit(hash256_field, True)

pub fn mul_bytes(
  intermediate: State<Hash256>,
  bytes: ByteArray,
) -> State<Hash256> {
  mul_bit256(intermediate, bytes)
}

const mul_i256: Bitwise256Int = mulint(hash256_field)

pub fn mul_int(intermediate: State<Hash256>, int: Int) -> State<Hash256> {
  mul_i256(intermediate, int)
}

const neg256: fn(State<Hash256>) -> State<Hash256> = negbit(hash256_field)

pub fn neg(intermediate: State<Hash256>) -> State<Hash256> {
  neg256(intermediate)
}
