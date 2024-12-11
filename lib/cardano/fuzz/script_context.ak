use aiken/fuzz.{map3}
use cardano/script_context.{ScriptContext, ScriptInfo}
use cardano/transaction.{Redeemer, Transaction}

pub fn constrained_script_context(
  tx: Fuzzer<Transaction>,
  rdmr: Fuzzer<Redeemer>,
  info: Fuzzer<ScriptInfo>,
) -> Fuzzer<ScriptContext> {
  map3(tx, rdmr, info, fn(t, r, i) { ScriptContext(t, r, i) })
}
