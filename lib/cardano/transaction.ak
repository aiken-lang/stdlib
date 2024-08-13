use aiken/builtin
use aiken/collection.{Index}
use aiken/collection/dict.{Dict}
use aiken/collection/list
use aiken/hash.{Blake2b_256, Hash, blake2b_256}
use aiken/interval.{Interval}
use aiken/option
use cardano/assets.{Lovelace, PolicyId, Value}
use cardano/certificate.{Certificate}
use cardano/credential.{
  Address, Credential, DatumHash, Script, ScriptHash, VerificationKey,
  VerificationKeyHash,
}
use cardano/governance.{GovernanceActionId, ProposalProcedure, Vote, Voter}

pub type TransactionId =
  Hash<Blake2b_256, Transaction>

/// A context given to a script by the Cardano ledger when being executed.
///
/// The context contains information about the entire transaction that contains
/// the script. The transaction may also contain other scripts; to distinguish
/// between multiple scripts, the `ScriptInfo` contains a `purpose`
/// which indicates which script (or, for what purpose) of the transaction is
/// being executed.
pub type ScriptContext {
  transaction: Transaction,
  redeemer: Redeemer,
  info: ScriptInfo,
}

/// Characterizes the script information.
pub type ScriptInfo {
  /// For scripts executed as minting/burning policies, to insert
  /// or remove assets from circulation. It's parameterized by the identifier
  /// of the associated policy.
  Minting(PolicyId)
  /// For scripts that are used as payment credentials for addresses in
  /// transaction outputs. They govern the rule by which the output they
  /// reference can be spent.
  Spending(OutputReference, Option<Data>)
  /// For scripts that validate reward withdrawals from a reward account.
  ///
  /// The argument identifies the target reward account.
  Withdrawing(Credential)
  /// Needed when delegating to a pool using stake credentials defined as a
  /// Plutus script. This purpose is also triggered when de-registering such
  /// stake credentials.
  ///
  /// The Int is a 0-based index of the given `TxCert` in `certificates`.
  Publishing(Index, Certificate)
  /// Voting for a type of voter using a governance action id to vote
  /// yes / no / abstain inside a transaction.
  ///
  /// The voter is who is doing the governance action.
  Voting(Voter)
  /// Used to propose a governance action.
  ///
  /// A 0-based index of the given `ProposalProcedure` in `proposal_procedures`.
  Proposing(Index, ProposalProcedure)
}

/// Characterizes the script purpose.
pub type ScriptPurpose {
  /// For scripts executed as minting/burning policies, to insert
  /// or remove assets from circulation. It's parameterized by the identifier
  /// of the associated policy.
  Mint(PolicyId)
  /// For scripts that are used as payment credentials for addresses in
  /// transaction outputs. They govern the rule by which the output they
  /// reference can be spent.
  Spend(OutputReference)
  /// For scripts that validate reward withdrawals from a reward account.
  ///
  /// The argument identifies the target reward account.
  Withdraw(Credential)
  /// Needed when delegating to a pool using stake credentials defined as a
  /// Plutus script. This purpose is also triggered when de-registering such
  /// stake credentials.
  ///
  /// The Int is a 0-based index of the given `TxCert` in `certificates`.
  Publish { certificate_index: Int, certificate: Certificate }
  /// Voting for a type of voter using a governance action id to vote
  /// yes / no / abstain inside a transaction.
  ///
  /// The voter is who is doing the governance action.
  Vote(Voter)
  /// Used to propose a governance action.
  ///
  /// A 0-based index of the given `ProposalProcedure` in `proposal_procedures`.
  Propose(Int, ProposalProcedure)
}

/// A Cardano `Transaction`, as seen by Plutus scripts.
///
/// Note that this is a representation of a transaction, and not the 1:1
/// translation of the transaction as seen by the ledger. In particular,
/// Plutus scripts can't see inputs locked by bootstrap addresses, outputs
/// to bootstrap addresses or just transaction metadata.
pub type Transaction {
  inputs: List<Input>,
  reference_inputs: List<Input>,
  outputs: List<Output>,
  fee: Lovelace,
  mint: Value,
  certificates: List<Certificate>,
  /// ⚠️ | Withdrawals are ordered by ascending [Credential](./credential.html#Credential). Yet, note that script credentials are treated as lower values than verification key credentials.
  /// --- | ---
  withdrawals: Pairs<Credential, Lovelace>,
  validity_range: ValidityRange,
  extra_signatories: List<VerificationKeyHash>,
  /// ⚠️ | Redeemers are ordered by ascending [ScriptPurpose](./governance.html#ScriptPurpose).
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  datums: Dict<DatumHash, Data>,
  id: TransactionId,
  /// ⚠️ | Votes are ordered by ascending [Voter](./governance.html#Voter) and [GovernanceActionId](./governance.html#GovernanceActionId).<br/>First constructor variants in a type are treated as lower indices; except for [Credential](./credential.html#Credential) where stake credentials are treated as lower values than verification key credentials.
  /// --- | ---
  votes: Pairs<Voter, Pairs<GovernanceActionId, Vote>>,
  proposal_procedures: List<ProposalProcedure>,
  current_treasury_amount: Option<Lovelace>,
  treasury_donation: Option<Lovelace>,
}

/// A placeholder / empty `Transaction` to serve as a base in a transaction
/// builder. This is particularly useful for constructing test transactions.
///
/// Every field is empty or null, and we have in particular:
///
/// ```aiken
/// use aiken/transaction
///
/// transaction.placeholder().id ==
///   #"0000000000000000000000000000000000000000000000000000000000000000"
///
/// transaction.placeholder().validity_range == interval.everything()
/// ```
pub fn placeholder() -> Transaction {
  Transaction {
    inputs: [],
    reference_inputs: [],
    outputs: [],
    fee: 0,
    mint: assets.zero(),
    certificates: [],
    withdrawals: [],
    validity_range: interval.everything(),
    extra_signatories: [],
    redeemers: [],
    datums: dict.new(),
    id: #"0000000000000000000000000000000000000000000000000000000000000000",
    votes: [],
    proposal_procedures: [],
    current_treasury_amount: None,
    treasury_donation: None,
  }
}

/// A number of milliseconds since 00:00:00 UTC on 1 January 1970.
pub type PosixTime =
  Int

/// An interval of POSIX time, measured in number milliseconds since 1970-01-01T00:00:00Z.
pub type ValidityRange =
  Interval<PosixTime>

/// An `Input` made of an output reference and, the resolved value associated with that output.
pub type Input {
  output_reference: OutputReference,
  output: Output,
}

/// An `OutputReference` is a unique reference to an output on-chain. The `output_index`
/// corresponds to the position in the output list of the transaction (identified by its id)
/// that produced that output
pub type OutputReference {
  transaction_id: Hash<Blake2b_256, Transaction>,
  output_index: Int,
}

/// A transaction `Output`, with an address, a value and optional datums and script references.
pub type Output {
  address: Address,
  value: Value,
  datum: Datum,
  reference_script: Option<ScriptHash>,
}

/// An output `Datum`.
pub type Datum {
  NoDatum
  /// A datum referenced by its hash digest.
  DatumHash(DatumHash)
  /// A datum completely inlined in the output.
  InlineDatum(Data)
}

/// A type-alias for Redeemers, passed to scripts for validation. The `Data` is
/// opaque because it is user-defined and it is the script's responsibility to
/// parse it into its expected form.
pub type Redeemer =
  Data

/// Find an input by its [`OutputReference`](#OutputReference). This is typically used in
/// combination with the `Spend` [`ScriptPurpose`](#ScriptPurpose) to find a script's own
/// input.
///
/// ```aiken
/// validator {
///   fn(datum, redeemer, ctx: ScriptContext) {
///     expect Spend(my_output_reference) =
///       ctx.purpose
///
///     expect Some(input) =
///       ctx.transaction.inputs
///         |> transaction.find_input(my_output_reference)
///   }
/// }
/// ```
pub fn find_input(
  inputs: List<Input>,
  output_reference: OutputReference,
) -> Option<Input> {
  inputs
    |> list.find(fn(input) { input.output_reference == output_reference })
}

/// Find a [`Datum`](#Datum) by its hash, if present. The function looks first for
/// datums in the witness set, and then for inline datums if it doesn't find any in
/// witnesses.
pub fn find_datum(
  outputs: List<Output>,
  datums: Dict<DatumHash, Data>,
  datum_hash: DatumHash,
) -> Option<Data> {
  datums
    |> dict.get(datum_hash)
    |> option.or_try(
        fn() {
          outputs
            |> list.filter_map(
                fn(output) {
                  when output.datum is {
                    InlineDatum(data) ->
                      if
                      blake2b_256(builtin.serialise_data(data)) == datum_hash{

                        Some(data)
                      } else {
                        None
                      }
                    _ -> None
                  }
                },
              )
            |> list.head
        },
      )
}

/// Find all outputs that are paying into the given script hash, if any. This is useful for
/// contracts running over multiple transactions.
pub fn find_script_outputs(
  outputs: List<Output>,
  script_hash: ScriptHash,
) -> List<Output> {
  outputs
    |> list.filter(
        fn(output) {
          when output.address.payment_credential is {
            Script(addr_script_hash) -> script_hash == addr_script_hash
            VerificationKey(_) -> False
          }
        },
      )
}
