use aiken/builtin
use aiken/dict.{Dict}
use aiken/hash.{Blake2b_224, Blake2b_256, Hash, blake2b_256}
use aiken/interval.{Interval}
use aiken/list
use aiken/math/rational.{Rational}
use aiken/option
use aiken/time.{PosixTime}
use aiken/transaction/credential.{
  Address, Credential, Script, ScriptCredential, StakeCredential,
  VerificationKey, VerificationKeyCredential,
}
use aiken/transaction/value.{PolicyId, Value}

pub type DRepCredential {
  member: Credential,
}

pub type DRep {
  DRep(DRepCredential)
  DRepAlwaysAbstain
  DRepAlwaysNoConfidence
}

pub type Delegatee {
  DelegStake(PubKeyHash)
  DelegVote(DRep)
  DelegStakeVote(PubKeyHash, DRep)
}

pub type Certificate {
  // Register staking credential with an optional deposit amount
  RegisterStaking(Credential, Option<Lovelace>)
  // Un-Register staking credential with an optional refund amount
  UnRegisterStaking(Credential, Option<Lovelace>)
  // Delegate staking credential to a Delegatee
  TxCertDelegStaking(Credential, Delegatee)
  // Register and delegate staking credential to a Delegatee in one certificate. Noter that
  // deposit is mandatory.
  TxCertRegDeleg(Credential, Delegatee, Lovelace)
  // Register a DRep with a deposit value. The optional anchor is omitted.
  TxCertRegDRep(DRepCredential, Lovelace)
  // Update a DRep. The optional anchor is omitted.
  TxCertUpdateDRep(DRepCredential)
  // UnRegister a DRep with mandatory refund value
  TxCertUnRegDRep(DRepCredential, Lovelace)
  // A digest of the PoolParams
  TxCertPoolRegister(
    // poolId
    PubKeyHash,
    // pool VFR
    PubKeyHash,
  )
  // The retirement certificate and the Epoch in which the retirement will take place
  TxCertPoolRetire(PubKeyHash, Int)
  // Authorize a Hot credential for a specific Committee member's cold credential
  TxCertAuthHotCommittee(ColdCommitteeCredential, HotCommitteeCredential)
  TxCertResignColdCommittee(ColdCommitteeCredential)
}

pub type GovernanceActionId {
  gaid_tx_id: TransactionId,
  gaid_tx_idx: Int,
}

pub type ChangedParameters {
  new_parameters: Data,
}

pub type ProtocolVersion {
  major: Int,
  minor: Int,
}

pub type ColdCommitteeCredential {
  member: Credential,
}

pub type Constitution {
  constitution_script: Option<ScriptHash>,
}

pub type GovernanceAction {
  //
  ParameterChange(
    Option<GovernanceActionId>,
    ChangedParameters,
    // Hash of the constitution script
    Option<ScriptHash>,
  )
  // proposal to update protocol version
  HardForkInitiation(Option<GovernanceActionId>, ProtocolVersion)
  //
  TreasuryWithdrawals(
    Dict<Credential, Lovelace>,
    // Hash of the constitution script
    Option<ScriptHash>,
  )
  //
  NoConfidence(Option<GovernanceActionId>)
  //
  UpdateCommittee(
    Option<GovernanceActionId>,
    // Committee members to be removed
    List<ColdCommitteeCredential>,
    // Committee members to be added
    Dict<ColdCommitteeCredential, Int>,
    // New quorum
    Rational,
  )
  //
  NewConstitution(Option<GovernanceActionId>, Constitution)
  //
  InfoAction
}

pub type ProposalProcedure {
  deposit: Lovelace,
  return_addr: Credential,
  governance_action: GovernanceAction,
}

pub type HotCommitteeCredential {
  member: Credential,
}

pub type Voter {
  CommitteeVoter(HotCommitteeCredential)
  DRepVoter(DRepCredential)
  StakePoolVoter(PubKeyHash)
}

pub type Vote {
  VoteNo
  VoteYes
  Abstain
}

/// Lovelace is now a type wrapper for Int.
pub type Lovelace =
  Int

pub type PubKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type ScriptHash =
  Hash<Blake2b_224, Script>

/// A context given to a script by the Cardano ledger when being executed.
///
/// The context contains information about the entire transaction that contains
/// the script. The transaction may also contain other scripts; to distinguish
/// between multiple scripts, the `ScriptContext` also contains a `purpose`
/// which indicates which script (or, for what purpose) of the transaction is
/// being executed.
pub type ScriptContext {
  transaction: Transaction,
  purpose: ScriptPurpose,
}

/// Characterizes the kind of script being executed.
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
  WithdrawFrom(StakeCredential)
  /// Needed when delegating to a pool using stake credentials defined as a
  /// Plutus script. This purpose is also triggered when de-registering such
  /// stake credentials.
  ///
  /// The Int is a 0-based index of the given `TxCert` in `certificates`.
  Publish(Int, Certificate)
  /// Voting for a type of voter using a governance action id to vote
  /// yes / no / abstain inside a transaction.
  ///
  /// The voter is who is doing the governance action.
  Voting(Voter)
  /// Used to propose a governance action.
  ///
  /// A 0-based index of the given `ProposalProcedure` in `proposal_procedures`.
  Proposing(Int, ProposalProcedure)
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
  // ^ the fee is now lovelace
  mint: Value,
  // ^ minted value is now back to a value
  certificates: List<Certificate>,
  withdrawals: Pairs<Credential, Lovelace>,
  validity_range: ValidityRange,
  extra_signatories: List<PubKeyHash>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  datums: Dict<Hash<Blake2b_256, Data>, Data>,
  id: TransactionId,
  // ^ new tx id
  // all new fields below for v3
  votes: Dict<Voter, Dict<GovernanceActionId, Vote>>,
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
/// transaction.placeholder().id == TransactionId {
///   hash: #"0000000000000000000000000000000000000000000000000000000000000000",
/// }
///
/// transaction.placeholder().validity_range == interval.everything()
/// ```
pub fn placeholder() -> Transaction {
  Transaction {
    inputs: [],
    reference_inputs: [],
    outputs: [],
    fee: 0,
    mint: value.zero(),
    certificates: [],
    withdrawals: [],
    validity_range: interval.everything(),
    extra_signatories: [],
    redeemers: [],
    datums: dict.new(),
    id: #"0000000000000000000000000000000000000000000000000000000000000000",
    votes: dict.new(),
    proposal_procedures: [],
    current_treasury_amount: None,
    treasury_donation: None,
  }
}

/// An interval of POSIX time, measured in number milliseconds since 1970-01-01T00:00:00Z.
pub type ValidityRange =
  Interval<PosixTime>

/// A unique transaction identifier, as the hash of a transaction body. Note that the transaction id
/// isn't a direct hash of the `Transaction` as visible on-chain. Rather, they correspond to hash
/// digests of transaction body as they are serialized on the network.
pub type TransactionId =
  Hash<Blake2b_256, Transaction>

/// An `Input` made of an output reference and, the resolved value associated with that output.
pub type Input {
  output_reference: OutputReference,
  output: Output,
}

/// An `OutputReference` is a unique reference to an output on-chain. The `output_index`
/// corresponds to the position in the output list of the transaction (identified by its id)
/// that produced that output
pub type OutputReference {
  transaction_id: TransactionId,
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
  DatumHash(Hash<Blake2b_256, Data>)
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
  datums: Dict<Hash<Blake2b_256, Data>, Data>,
  datum_hash: Hash<Blake2b_256, Data>,
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
            ScriptCredential(addr_script_hash) ->
              script_hash == addr_script_hash
            VerificationKeyCredential(_) -> False
          }
        },
      )
}
