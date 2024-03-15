use aiken/builtin.{
  append_bytearray, choose_data, cons_bytearray, decode_utf8, index_bytearray,
  length_of_bytearray, quotient_integer, remainder_integer, serialise_data,
  un_b_data, un_constr_data, un_i_data, un_list_data, un_map_data,
}
use aiken/list

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
/// serialise(42) == #"182a"
/// serialise(#"a1b2") == #"42a1b2"
/// serialise([]) == #"80"
/// serialise((1, 2)) == #"9f0102ff"
/// serialise((1, #"ff", 3)) == #"9f0141ff03ff"
/// serialise([(1, #"ff")]) == #"a10141ff"
/// serialise(Some(42)) == #"d8799f182aff"
/// serialise(None) == #"d87a80"
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
  serialise([(1, #"ff")]) == #"a10141ff"
}

test serialise_7() {
  serialise(Some(42)) == #"d8799f182aff"
}

test serialise_8() {
  serialise(None) == #"d87a80"
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
/// diagnostic(42) == "42"
/// diagnostic(#"a1b2") == "h'A1B2'"
/// diagnostic([1, 2, 3]) == "[_ 1, 2, 3]"
/// diagnostic([]) == "[]"
/// diagnostic((1, 2)) == "[_ 1, 2]"
/// diagnostic((1, #"ff", 3)) == "[_ 1, h'FF', 3]"
/// diagnostic([(1, #"ff")]) == "{_ 1: h'FF' }"
/// diagnostic(Some(42)) == "121([_ 42])"
/// diagnostic(None) == "122([])"
/// ```
pub fn diagnostic(self: Data) -> String {
  do_diagnostic(self, #"")
    |> decode_utf8
}

/// UTF-8 lookup table. Comes in handy to decipher the code below.
///
/// | Symbol | Decimal | Hex  |
/// | ---    | ---     | ---  |
/// |        | 32      | 0x20 |
/// | '      | 39      | 0x27 |
/// | (      | 40      | 0x28 |
/// | )      | 41      | 0x29 |
/// | ,      | 44      | 0x2c |
/// | 0      | 48      | 0x30 |
/// | :      | 58      | 0x3a |
/// | A      | 65      | 0x41 |
/// | [      | 91      | 0x5b |
/// | ]      | 93      | 0x5d |
/// | _      | 95      | 0x5f |
/// | h      | 104     | 0x68 |
/// | {      | 123     | 0x7b |
/// | }      | 125     | 0x7d |
fn do_diagnostic(self: Data, builder: ByteArray) -> ByteArray {
  choose_data(
    self,
    {
      // -------- Constr

      let (constr, fields) = un_constr_data(self)

      // NOTE: This is fundamentally the same logic for serializing list. However, the compiler
      // doesn't support mutual recursion just yet, so we can't extract that logic in a separate
      // function.
      //
      // See [aiken-lang/aiken#389](https://github.com/aiken-lang/aiken/pull/389)
      let builder =
        when fields is {
          [] -> append_bytearray(#"5b5d29", builder)
          _ -> {
            let (_, bytes) =
              list.foldr(
                fields,
                (#"5d", append_bytearray(#"29", builder)),
                fn(e: Data, st: (ByteArray, ByteArray)) {
                  (#"2c20", do_diagnostic(e, append_bytearray(st.1st, st.2nd)))
                },
              )
            append_bytearray(#"5b5f20", bytes)
          }
        }

      let constr_tag =
        if constr < 7 {
          121 + constr
        } else if constr < 128 {
          1280 + constr - 7
        } else {
          fail @"What are you doing? No I mean, seriously."
        }

      builder
        |> append_bytearray(#"28", _)
        |> from_int(constr_tag, _)
    },
    {
      // -------- Map

      let elems = un_map_data(self)
      when elems is {
        [] -> append_bytearray(#"7b7d", builder)
        _ -> {
          let (_, bytes) =
            list.foldr(
              elems,
              (#"207d", builder),
              fn(e: (Data, Data), st: (ByteArray, ByteArray)) {
                let value =
                  do_diagnostic(e.2nd, append_bytearray(st.1st, st.2nd))
                (
                  #"2c20",
                  do_diagnostic(e.1st, append_bytearray(#"3a20", value)),
                )
              },
            )
          append_bytearray(#"7b5f20", bytes)
        }
      }
    },
    {
      // -------- List

      let elems = un_list_data(self)
      when elems is {
        [] -> append_bytearray(#"5b5d", builder)
        _ -> {
          let (_, bytes) =
            list.foldr(
              elems,
              (#"5d", builder),
              fn(e: Data, st: (ByteArray, ByteArray)) {
                (#"2c20", do_diagnostic(e, append_bytearray(st.1st, st.2nd)))
              },
            )
          append_bytearray(#"5b5f20", bytes)
        }
      }
    },
    // -------- Integer
    self
      |> un_i_data
      |> from_int(builder),
    {
      // -------- ByteArray
      let bytes = un_b_data(self)

      bytes
        |> encode_base16(
            length_of_bytearray(bytes) - 1,
            append_bytearray(#"27", builder),
          )
        |> append_bytearray(#"6827", _)
    },
  )
}

fn encode_base16(bytes: ByteArray, ix: Int, builder: ByteArray) -> ByteArray {
  if ix < 0 {
    builder
  } else {
    let byte = index_bytearray(bytes, ix)
    let msb = byte / 16
    let lsb = byte % 16
    let builder =
      cons_bytearray(
        msb + if msb < 10 {
          48
        } else {
          55
        },
        cons_bytearray(
          lsb + if lsb < 10 {
            48
          } else {
            55
          },
          builder,
        ),
      )
    encode_base16(bytes, ix - 1, builder)
  }
}

fn from_int(i: Int, digits: ByteArray) -> ByteArray {
  if i == 0 {
    append_bytearray(#"30", digits)
  } else if i < 0 {
    append_bytearray(#"2d", from_int(-i, digits))
  } else {
    do_from_int(
      quotient_integer(i, 10),
      cons_bytearray(remainder_integer(i, 10) + 48, digits),
    )
  }
}

fn do_from_int(i: Int, digits: ByteArray) -> ByteArray {
  if i <= 0 {
    digits
  } else {
    do_from_int(
      quotient_integer(i, 10),
      cons_bytearray(remainder_integer(i, 10) + 48, digits),
    )
  }
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
  diagnostic([(1, #"ff")]) == @"{_ 1: h'FF' }"
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
