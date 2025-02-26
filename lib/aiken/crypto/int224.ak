use aiken/builtin
use aiken/crypto/bitwise.{
  State, add_bits as addbit, add_int as addint, mul_bits as mulbit,
  mul_int as mulint, neg as negbit, sub_bits as subbit, sub_int as subint,
}

pub type Hash224 =
  ByteArray

pub const hash224_field =
  builtin.replicate_byte(28, 0)
    |> builtin.cons_bytearray(1, _)
    |> builtin.bytearray_to_integer(True, _)

pub fn to_bytes(intermediate: State<Hash224>) -> ByteArray {
  bitwise.to_int(intermediate)
    |> builtin.integer_to_bytearray(True, 28, _)
}

pub fn to_int(intermediate: State<Hash224>) -> Int {
  bitwise.to_int(intermediate)
}

pub fn from_bytes(bytes: Hash224) -> State<Hash224> {
  bytes
    |> builtin.bytearray_to_integer(True, _)
    |> bitwise.from_int(hash224_field)
}

pub fn from_int(int: Int) -> State<Hash224> {
  bitwise.from_int(int, hash224_field)
}

type Bitwise224Bytes =
  fn(State<Hash224>, ByteArray) -> State<Hash224>

type Bitwise224Int =
  fn(State<Hash224>, Int) -> State<Hash224>

const add_bit224: Bitwise224Bytes = addbit(hash224_field, True)

pub fn add_bytes(
  intermediate: State<Hash224>,
  bytes: ByteArray,
) -> State<Hash224> {
  add_bit224(intermediate, bytes)
}

const add_i224: Bitwise224Int = addint(hash224_field)

pub fn add_int(intermediate: State<Hash224>, int: Int) -> State<Hash224> {
  add_i224(intermediate, int)
}

const sub_i224: Bitwise224Int = subint(hash224_field)

pub fn sub_int(intermediate: State<Hash224>, int: Int) -> State<Hash224> {
  sub_i224(intermediate, int)
}

const sub_bit224: Bitwise224Bytes = subbit(hash224_field, True)

pub fn sub_bytes(
  intermediate: State<Hash224>,
  bytes: ByteArray,
) -> State<Hash224> {
  sub_bit224(intermediate, bytes)
}

const mul_bit224: Bitwise224Bytes = mulbit(hash224_field, True)

pub fn mul_bytes(
  intermediate: State<Hash224>,
  bytes: ByteArray,
) -> State<Hash224> {
  mul_bit224(intermediate, bytes)
}

const mul_i224: Bitwise224Int = mulint(hash224_field)

pub fn mul_int(intermediate: State<Hash224>, int: Int) -> State<Hash224> {
  mul_i224(intermediate, int)
}

const neg224: fn(State<Hash224>) -> State<Hash224> = negbit(hash224_field)

pub fn neg(intermediate: State<Hash224>) -> State<Hash224> {
  neg224(intermediate)
}
