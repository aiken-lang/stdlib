use aiken/collection/dict.{Dict}
use aiken/math/rational.{Rational}
use cardano/assets.{Lovelace}
use cardano/credential.{
  ColdCommitteeCredential, Credential, DRepCredential, HotCommitteeCredential,
  ScriptHash, VerificationKeyHash,
}

pub type DRep {
  FromCredential(DRepCredential)
  AlwaysAbstain
  AlwaysNoConfidence
}

pub type Delegatee {
  DelegateStake(VerificationKeyHash)
  DelegateVote(DRep)
  DelegateBoth(VerificationKeyHash, DRep)
}

pub type Vote {
  No
  Yes
  Abstain
}

pub type GovernanceActionId {
  transaction_id: ByteArray,
  index: Int,
}

pub type ChangedProtocolParameters {
  new_parameters: Data,
}

pub type ProtocolVersion {
  major: Int,
  minor: Int,
}

pub type Constitution {
  guardrails_script: Option<ScriptHash>,
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
  StakePoolVoter(VerificationKeyHash)
}
