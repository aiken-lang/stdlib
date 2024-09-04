use aiken
use aiken/builtin.{decode_utf8, serialise_data}

/// Serialise any value to binary, encoding using [CBOR](https://www.rfc-editor.org/rfc/rfc8949).
///
/// This is particularly useful in combination with hashing functions, as a way
/// to obtain a byte representation that matches the serialised representation
/// used by the ledger in the context of on-chain code.
///
/// Note that the output matches the output of [`diagnostic`](#diagnostic),
/// though with a different encoding. [`diagnostic`](#diagnostic) is merely a
/// textual representation of the CBOR encoding that is human friendly and
/// useful for debugging.
///
/// ```aiken
/// cbor.serialise(42) == #"182a"
/// cbor.serialise(#"a1b2") == #"42a1b2"
/// cbor.serialise([]) == #"80"
/// cbor.serialise((1, 2)) == #"9f0102ff"
/// cbor.serialise((1, #"ff", 3)) == #"9f0141ff03ff"
/// cbor.serialise([(1, #"ff")]) == #"a10141ff"
/// cbor.serialise(Some(42)) == #"d8799f182aff"
/// cbor.serialise(None) == #"d87a80"
/// ```
pub fn serialise(self: Data) -> ByteArray {
  serialise_data(self)
}

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

/// Obtain a String representation of _anything_. This is particularly (and only) useful for tracing
/// and debugging. This function is expensive and should not be used in any production code as it
/// will very likely explodes the validator's budget.
///
/// The output is a [CBOR diagnostic](https://www.rfc-editor.org/rfc/rfc8949#name-diagnostic-notation)
/// of the underlying on-chain binary representation of the data. It's not as
/// easy to read as plain Aiken code, but it is handy for troubleshooting values
/// _at runtime_. Incidentally, getting familiar with reading CBOR diagnostic is
/// a good idea in the Cardano world.
///
/// ```aiken
/// cbor.diagnostic(42) == "42"
/// cbor.diagnostic(#"a1b2") == "h'A1B2'"
/// cbor.diagnostic([1, 2, 3]) == "[_ 1, 2, 3]"
/// cbor.diagnostic([]) == "[]"
/// cbor.diagnostic((1, 2)) == "[_ 1, 2]"
/// cbor.diagnostic((1, #"ff", 3)) == "[_ 1, h'FF', 3]"
/// cbor.diagnostic([(1, #"ff")]) == "{_ 1: h'FF' }"
/// cbor.diagnostic(Some(42)) == "121([_ 42])"
/// cbor.diagnostic(None) == "122([])"
/// ```
pub fn diagnostic(self: Data) -> String {
  aiken.diagnostic(self, #"")
    |> decode_utf8
}

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
  let xs: List<(Int, Int)> =
    []
  diagnostic(xs) == @"[]"
}

test diagnostic_10_alt() {
  let xs: Pairs<Int, Int> =
    []
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
