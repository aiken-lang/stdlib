////  This Source Code Form is subject to the terms of the Mozilla Public
////  License, v. 2.0. If a copy of the MPL was not distributed with this
////  file, You can obtain one at http://mozilla.org/MPL/2.0/.
////  This is a modified distribution of https://github.com/CardanoSolutions/zhuli/blob/main/lib/aiken/fuzz/scenario.ak

use aiken/cbor.{serialise}
use aiken/collection/dict
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{ScriptHash, blake2b_256}
use aiken/fuzz.{and_then, byte, constant, map}
use cardano/address.{Credential, Script}
use cardano/assets.{PolicyId}
use cardano/certificate.{
  AuthorizeConstitutionalCommitteeProxy, Certificate, DelegateCredential,
  RegisterAndDelegateCredential, RegisterDelegateRepresentative,
  RetireFromConstitutionalCommittee, UnregisterCredential,
  UnregisterDelegateRepresentative, UpdateDelegateRepresentative,
}
use cardano/governance.{
  ConstitutionalCommitteeMember, DelegateRepresentative, Voter,
}
use cardano/script_context.{
  Minting, Publishing, ScriptContext, Spending, Voting, Withdrawing,
}
use cardano/transaction.{
  DatumHash, InlineDatum, Input, Mint, NoDatum, OutputReference, Publish, Spend,
  Transaction, Vote, Withdraw,
}

const max_tries: Int = 50

const max_byte: Int = 255

pub type Label =
  String

pub type Scenario<st> {
  Done
  Scenario(List<Label>, st, Transaction)
}

// ## Constructing

pub fn ok(
  initial_state: st,
  step: fn(st, List<Input>) -> Fuzzer<Scenario<st>>,
) -> Fuzzer<List<Transaction>> {
  map(gen_scenario_repeatedly(True, initial_state, step, 0), fn(x) { x.2nd })
}

pub fn ko(
  initial_state: st,
  step: fn(st, List<Input>) -> Fuzzer<Scenario<st>>,
) -> Fuzzer<(List<Label>, List<Transaction>)> {
  gen_scenario_repeatedly(False, initial_state, step, 0)
}

fn gen_scenario_repeatedly(
  keep_ok: Bool,
  initial_state: st,
  step: fn(st, List<Input>) -> Fuzzer<Scenario<st>>,
  n: Int,
) -> Fuzzer<(List<Label>, List<Transaction>)> {
  if n > max_tries {
    if keep_ok {
      fail @"fail to generate O.K. scenarios: too many K.O. ones"
    } else {
      fail @"fail to generate K.O. scenarios: too many O.K. ones"
    }
  } else {
    let scenario <- and_then(gen_scenario([], initial_state, step))
    when scenario is {
      ([], []) -> constant(([], []))
      ([], txs) ->
        if keep_ok {
          constant(([], txs))
        } else {
          gen_scenario_repeatedly(keep_ok, initial_state, step, n + 1)
        }
      (labels, txs) ->
        if keep_ok {
          gen_scenario_repeatedly(keep_ok, initial_state, step, n + 1)
        } else {
          constant((labels, txs))
        }
    }
  }
}

fn gen_scenario(
  utxo: List<Input>,
  st: st,
  step: fn(st, List<Input>) -> Fuzzer<Scenario<st>>,
) -> Fuzzer<(List<Label>, List<Transaction>)> {
  let next <- and_then(step(st, utxo))
  when next is {
    Done -> constant(([], []))
    Scenario([], st_new, tx) -> {
      let transaction_id = blake2b_256(serialise(tx))
      let utxo =
        list.indexed_foldr(
          tx.outputs,
          [],
          fn(output_index, output, tail) {
            [
              Input {
                output_reference: OutputReference {
                  transaction_id,
                  output_index,
                },
                output,
              },
              ..tail
            ]
          },
        )
      let (labels, txs) <- and_then(gen_scenario(utxo, st_new, step))
      constant((labels, [tx, ..txs]))
    }
    Scenario(labels, _, tx) -> constant((labels, [tx]))
  }
}

// ## Inspecting

pub type Outcome {
  Ok
  Ko
}

/// A generator meant to analyze the scenario generator, to control that it is
/// relatively well-balanced between O.K. and K.O. scenarios.
pub fn report_coverage(
  initial_state: st,
  step: fn(st, List<Input>) -> Fuzzer<Scenario<st>>,
) -> Fuzzer<Outcome> {
  let scenario <- map(gen_scenario([], initial_state, step))
  when scenario is {
    ([], []) -> fail @"generated empty scenario?"
    ([], _txs) -> Ok
    (_labels, _txs) -> Ko
  }
}

// ## Running

/// Run a given scenario for a given set of handlers.
pub fn run(
  scenario: List<Transaction>,
  script: ScriptHash,
  mint: fn(Data, PolicyId, Transaction) -> Bool,
  spend: fn(Option<Data>, Data, OutputReference, Transaction) -> Bool,
  withdraw: fn(Data, Credential, Transaction) -> Bool,
  publish: fn(Data, Certificate, Transaction) -> Bool,
  vote: fn(Data, Voter, Transaction) -> Bool,
) {
  when scenario is {
    [] -> Void
    [next, ..tail] -> {
      expect mint_handlers(next, script, mint)
      expect spend_handlers(next, script, spend)
      expect withdraw_handlers(next, script, withdraw)
      expect publish_handlers(next, script, publish)
      expect vote_handlers(next, script, vote)
      run(tail, script, mint, spend, withdraw, publish, vote)
    }
  }
}

pub fn else_to_mint(
  mint: fn(ScriptContext) -> Bool,
) -> fn(Data, PolicyId, Transaction) -> Bool {
  fn(r: Data, p: PolicyId, t: Transaction) -> Bool {
    mint(ScriptContext(t, r, Minting(p)))
  }
}

fn mint_handlers(
  self: Transaction,
  script: ScriptHash,
  mint: fn(Data, PolicyId, Transaction) -> Bool,
) -> Bool {
  list.foldr(
    assets.policies(self.mint),
    True,
    fn(policy_id, st) {
      if policy_id == script {
        and {
          st,
          {
            expect Some(redeemer) =
              pairs.get_first(self.redeemers, Mint(policy_id))
            mint(redeemer, policy_id, self)
          },
        }
      } else {
        st
      }
    },
  )
}

pub fn else_to_spend(spend: fn(ScriptContext) -> Bool) {
  fn(d: Option<Data>, r: Data, o_ref: OutputReference, t: Transaction) -> Bool {
    spend(ScriptContext(t, r, Spending(o_ref, d)))
  }
}

fn spend_handlers(
  self: Transaction,
  script: ScriptHash,
  spend: fn(Option<Data>, Data, OutputReference, Transaction) -> Bool,
) -> Bool {
  list.foldr(
    self.inputs,
    True,
    fn(input, st) {
      if input.output.address.payment_credential == Script(script) {
        and {
          st,
          {
            expect Some(redeemer) =
              pairs.get_first(self.redeemers, Spend(input.output_reference))
            let datum =
              when input.output.datum is {
                NoDatum -> None
                DatumHash(digest) -> dict.get(self.datums, digest)
                InlineDatum(datum) -> Some(datum)
              }
            spend(datum, redeemer, input.output_reference, self)
          },
        }
      } else {
        st
      }
    },
  )
}

pub fn else_to_withdraw(withdraw: fn(ScriptContext) -> Bool) {
  fn(r: Data, cred: Credential, t: Transaction) -> Bool {
    withdraw(ScriptContext(t, r, Withdrawing(cred)))
  }
}

fn withdraw_handlers(
  self: Transaction,
  script: ScriptHash,
  withdraw: fn(Data, Credential, Transaction) -> Bool,
) -> Bool {
  pairs.foldr(
    self.withdrawals,
    True,
    fn(account, _amount, st) {
      if account == Script(script) {
        and {
          st,
          {
            expect Some(redeemer) =
              pairs.get_first(self.redeemers, Withdraw(account))
            withdraw(redeemer, account, self)
          },
        }
      } else {
        st
      }
    },
  )
}

pub fn else_to_publish(publish: fn(ScriptContext) -> Bool) {
  fn(r: Data, c: Certificate, t: Transaction) -> Bool {
    expect Some(ix) = list.index_of(t.certificates, c)
    publish(ScriptContext(t, r, Publishing(ix, c)))
  }
}

fn publish_handlers(
  self: Transaction,
  script: ScriptHash,
  publish: fn(Data, Certificate, Transaction) -> Bool,
) -> Bool {
  list.indexed_foldr(
    self.certificates,
    True,
    fn(ix, certificate, st) {
      when certificate is {
        UnregisterCredential { credential, .. } |
        DelegateCredential { credential, .. } |
        RegisterAndDelegateCredential { credential, .. } |
        RegisterDelegateRepresentative {
          delegate_representative: credential,
          ..
        } |
        UpdateDelegateRepresentative { delegate_representative: credential } |
        UnregisterDelegateRepresentative {
          delegate_representative: credential,
          ..
        } |
        AuthorizeConstitutionalCommitteeProxy {
          constitutional_committee_member: credential,
          ..
        } |
        RetireFromConstitutionalCommittee {
          constitutional_committee_member: credential,
        } ->
          if credential == Script(script) {
            and {
              st,
              {
                expect Some(redeemer) =
                  pairs.get_first(self.redeemers, Publish(ix, certificate))
                publish(redeemer, certificate, self)
              },
            }
          } else {
            st
          }

        _ -> st
      }
    },
  )
}

pub fn else_to_vote(vote: fn(ScriptContext) -> Bool) {
  fn(r: Data, v: Voter, t: Transaction) -> Bool {
    vote(ScriptContext(t, r, Voting(v)))
  }
}

fn vote_handlers(
  self: Transaction,
  script: ScriptHash,
  vote: fn(Data, Voter, Transaction) -> Bool,
) -> Bool {
  pairs.foldr(
    self.votes,
    True,
    fn(voter, _vote, st) {
      let relevant = or {
          voter == DelegateRepresentative(Script(script)),
          voter == ConstitutionalCommitteeMember(Script(script)),
        }

      if relevant {
        and {
          st,
          {
            expect Some(redeemer) = pairs.get_first(self.redeemers, Vote(voter))
            vote(redeemer, voter, self)
          },
        }
      } else {
        st
      }
    },
  )
}

// ## Fuzzing

/// The 'pivot' represents a value between 0 and 255 which represents the
/// probability of NOT forking the main scenario on a branch. It needs to be
/// high enough to have a high probability chance of generating valid scenarios
/// despite many forks, but small enough that forks still occur.
///
/// Ideally, one wants `((255 - pivot) / 255)^num_forks ~ 0.5`
pub fn fork(
  pivot: Int,
  main: fn() -> Fuzzer<a>,
  branch: fn() -> Fuzzer<a>,
) -> Fuzzer<a> {
  let toss <- and_then(byte())
  if toss < pivot {
    main()
  } else {
    branch()
  }
}

pub fn fork2(
  pivot: Int,
  main: fn() -> Fuzzer<a>,
  branch1: fn() -> Fuzzer<a>,
  branch2: fn() -> Fuzzer<a>,
) -> Fuzzer<a> {
  let toss <- and_then(byte())
  let step = ( max_byte - pivot ) / 2
  if toss < pivot {
    main()
  } else if toss < pivot + step {
    branch1()
  } else {
    branch2()
  }
}

pub fn fork3(
  pivot: Int,
  main: fn() -> Fuzzer<a>,
  branch1: fn() -> Fuzzer<a>,
  branch2: fn() -> Fuzzer<a>,
  branch3: fn() -> Fuzzer<a>,
) -> Fuzzer<a> {
  let toss <- and_then(byte())
  let step = ( max_byte - pivot ) / 3
  if toss < pivot {
    main()
  } else if toss < pivot + step {
    branch1()
  } else if toss < pivot + 2 * step {
    branch2()
  } else {
    branch3()
  }
}

pub fn fork4(
  pivot: Int,
  main: Fuzzer<a>,
  branch1: Fuzzer<a>,
  branch2: Fuzzer<a>,
  branch3: Fuzzer<a>,
  branch4: Fuzzer<a>,
) -> Fuzzer<a> {
  let toss <- and_then(byte())
  let step = ( max_byte - pivot ) / 4
  if toss < pivot {
    main
  } else if toss < pivot + step {
    branch1
  } else if toss < pivot + 2 * step {
    branch2
  } else if toss < pivot + 3 * step {
    branch3
  } else {
    branch4
  }
}
