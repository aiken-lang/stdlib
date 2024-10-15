use aiken/cbor.{deserialise, diagnostic, serialise}
use aiken/fuzz

// ------------------------------------------------------------------ diagnostic

test diagnostic_1() {
  diagnostic(42) == @"42"
}

test diagnostic_2() {
  diagnostic(#"a1b2") == @"h'A1B2'"
}

test diagnostic_3() {
  diagnostic([1, 2, 3]) == @"[_ 1, 2, 3]"
}

test diagnostic_4() {
  diagnostic([]) == @"[]"
}

test diagnostic_5() {
  diagnostic((1, 2)) == @"[_ 1, 2]"
}

test diagnostic_6() {
  diagnostic((1, #"ff", 3)) == @"[_ 1, h'FF', 3]"
}

test diagnostic_7() {
  diagnostic([(1, #"ff")]) == @"[_ [_ 1, h'FF']]"
}

test diagnostic_7_alt() {
  diagnostic([Pair(1, #"ff")]) == @"{_ 1: h'FF' }"
}

test diagnostic_8() {
  diagnostic(Some(42)) == @"121([_ 42])"
}

test diagnostic_9() {
  diagnostic(None) == @"122([])"
}

test diagnostic_10() {
  let xs: List<(Int, Int)> = []
  diagnostic(xs) == @"[]"
}

test diagnostic_10_alt() {
  let xs: Pairs<Int, Int> = []
  diagnostic(xs) == @"{}"
}

type Foo {
  foo: Bar,
}

type Bar {
  A
  B(Int)
}

test diagnostic_11() {
  diagnostic(Foo { foo: A }) == @"121([_ 121([])])"
}

test diagnostic_12() {
  diagnostic(Foo { foo: B(42) }) == @"121([_ 122([_ 42])])"
}

type Baz {
  a0: Int,
  b0: ByteArray,
}

test diagnostic_13() {
  diagnostic(Baz { a0: 14, b0: #"ff" }) == @"121([_ 14, h'FF'])"
}

test diagnostic_14() {
  diagnostic([0]) == @"[_ 0]"
}

test diagnostic_15() {
  diagnostic(-42) == @"-42"
}

test diagnostic_16() {
  diagnostic([-1, 0, 1]) == @"[_ -1, 0, 1]"
}

// ------------------------------------------------------------------ serialise

test serialise_1() {
  serialise(42) == #"182a"
}

test serialise_2() {
  serialise(#"a1b2") == #"42a1b2"
}

test serialise_3() {
  serialise([]) == #"80"
}

test serialise_4() {
  serialise((1, 2)) == #"9f0102ff"
}

test serialise_5() {
  serialise((1, #"ff", 3)) == #"9f0141ff03ff"
}

test serialise_6() {
  serialise([(1, #"ff")]) == #"9f9f0141ffffff"
}

test serialise_7() {
  serialise(Some(42)) == #"d8799f182aff"
}

test serialise_8() {
  serialise(None) == #"d87a80"
}

test serialise_9() {
  serialise([Pair(1, #"ff")]) == #"a10141ff"
}

// ------------------------------------------------------------------ deserialise

type AnyData {
  AnyInt(Int)
  AnyByteArray(ByteArray)
  AnyList(List<Int>)
  AnyPairs(Pairs<ByteArray, Int>)
  AnyUnaryConstr0(UnaryConstr0)
  AnyUnaryConstr1(UnaryConstr1)
  AnyUnaryConstr2(UnaryConstr2)
  AnyBinaryConstr0(BinaryConstr0)
  AnyBinaryConstr1(BinaryConstr1)
}

type UnaryConstr0 {
  UnaryConstr0
}

type UnaryConstr1 {
  field0: String,
}

type UnaryConstr2 {
  field0: Int,
  field1: List<List<ByteArray>>,
}

type BinaryConstr0 =
  Bool

type BinaryConstr1 =
  Option<Int>

fn any_pair(any_key: Fuzzer<k>, any_value: Fuzzer<v>) -> Fuzzer<Pair<k, v>> {
  let k <- fuzz.and_then(any_key)
  let v <- fuzz.map(any_value)
  Pair(k, v)
}

fn any_data() -> Fuzzer<AnyData> {
  fuzz.either6(
    {
      let i <- fuzz.map(fuzz.int())
      AnyInt(i)
    },
    {
      let bs <- fuzz.map(fuzz.bytearray())
      AnyByteArray(bs)
    },
    {
      let xs <- fuzz.map(fuzz.list(fuzz.int()))
      AnyList(xs)
    },
    {
      let ps <- fuzz.map(fuzz.list(any_pair(fuzz.bytearray(), fuzz.int())))
      AnyPairs(ps)
    },
    fuzz.either3(
      fuzz.constant(AnyUnaryConstr0(UnaryConstr0)),
      fuzz.constant(AnyUnaryConstr1(UnaryConstr1(@"lorem ipsum"))),
      {
        let i <- fuzz.and_then(fuzz.int())
        let xs <- fuzz.map(fuzz.list(fuzz.list(fuzz.bytearray())))
        AnyUnaryConstr2(UnaryConstr2(i, xs))
      },
    ),
    fuzz.either(
      {
        let b <- fuzz.map(fuzz.bool())
        AnyBinaryConstr0(b)
      },
      {
        let o <- fuzz.map(fuzz.option(fuzz.int()))
        AnyBinaryConstr1(o)
      },
    ),
  )
}

test prop_deserialise_any_data(any via any_data()) {
  when any is {
    AnyInt(i) -> {
      fuzz.label(@"Int")
      expect Some(data) = deserialise(serialise(i))
      expect i_decoded: Int = data
      i_decoded == i
    }
    AnyByteArray(bs) -> {
      fuzz.label(@"ByteArray")
      expect Some(data) = deserialise(serialise(bs))
      expect bs_decoded: ByteArray = data
      bs_decoded == bs
    }
    AnyList(xs) -> {
      fuzz.label(@"List")
      expect Some(data) = deserialise(serialise(xs))
      expect xs_decoded: List<Int> = data
      xs_decoded == xs
    }
    AnyPairs(ps) -> {
      fuzz.label(@"Pairs")
      expect Some(data) = deserialise(serialise(ps))
      expect ps_decoded: Pairs<ByteArray, Int> = data
      ps_decoded == ps
    }
    AnyUnaryConstr0(constr) -> {
      fuzz.label(@"(unary) Constr")
      expect Some(data) = deserialise(serialise(constr))
      expect constr_decoded: UnaryConstr0 = data
      constr_decoded == constr
    }
    AnyUnaryConstr1(constr) -> {
      fuzz.label(@"(unary) Constr")
      expect Some(data) = deserialise(serialise(constr))
      expect constr_decoded: UnaryConstr1 = data
      constr_decoded == constr
    }
    AnyUnaryConstr2(constr) -> {
      fuzz.label(@"(unary) Constr")
      expect Some(data) = deserialise(serialise(constr))
      expect constr_decoded: UnaryConstr2 = data
      constr_decoded == constr
    }
    AnyBinaryConstr0(constr) -> {
      fuzz.label(@"(binary) Constr")
      expect Some(data) = deserialise(serialise(constr))
      expect constr_decoded: BinaryConstr0 = data
      constr_decoded == constr
    }
    AnyBinaryConstr1(constr) -> {
      fuzz.label(@"(binary) Constr")
      expect Some(data) = deserialise(serialise(constr))
      expect constr_decoded: BinaryConstr1 = data
      constr_decoded == constr
    }
  }
}
