use aiken/dict.{Dict}
use aiken/math/rational.{Rational}
use aiken/transaction/credential.{
  ColdCommitteeCredential, Credential, DRepCredential, HotCommitteeCredential,
  PubKeyHash, ScriptHash,
}
use aiken/transaction/value.{Lovelace}

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

pub type Vote {
  VoteNo
  VoteYes
  Abstain
}

pub type GovernanceActionId {
  gaid_tx_id: ByteArray,
  gaid_tx_idx: Int,
}

pub type ChangedParameters {
  new_parameters: Data,
}

pub type ProtocolVersion {
  major: Int,
  minor: Int,
}

pub type Constitution {
  constitution_script: Option<ScriptHash>,
}

pub type GovernanceAction {
  //
  ProtocolParametersChange(
    Option<GovernanceActionId>,
    ChangedProtocolParameters,
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
  return_address: Credential,
  governance_action: GovernanceAction,
}

pub type Voter {
  CommitteeVoter(HotCommitteeCredential)
  DRepVoter(DRepCredential)
  StakePoolVoter(PubKeyHash)
}
