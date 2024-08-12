use cardano/assets.{Lovelace}
use cardano/credential.{Credential, StakePoolId, VerificationKeyHash}

/// An on-chain certificate attesting of some operation. Publishing
/// certificates / triggers different kind of rules; most of the time,
/// they require signatures from / specific keys.
pub type Certificate {
  // Register a stake credential with an optional deposit amount.
  // The deposit is always present when using the new registration certificate
  // format available since the Conway era.
  RegisterCredential { credential: Credential, deposit: Option<Lovelace> }
  // Un-Register a stake credential with an optional refund amount
  // The deposit is always present when using the new de-registration certificate
  // format available since the Conway era.
  UnregisterCredential { credential: Credential, refund: Option<Lovelace> }
  // Delegate stake to a [Delegate](#Delegate).
  DelegateCredential { credential: Credential, delegate: Delegate }
  // Register and delegate staking credential to a Delegatee in one certificate.
  RegisterAndDelegateCredential {
    credential: Credential,
    delegate: Delegate,
    deposit: Lovelace,
  }
  // Register a delegate representative (a.k.a DRep). The deposit is explicit and
  // is refunded when the delegate steps down (unregister).
  RegisterDelegateRepresentative {
    delegate_representative: Credential,
    deposit: Lovelace,
  }
  // Update a delegate representative (a.k.a DRep). The certificate also contains
  // metadata which aren't visible on-chain.
  UpdateDelegateRepresentative { delegate_representative: Credential }
  // UnRegister a delegate representative, and refund back its past deposit.
  UnregisterDelegateRepresentative {
    delegate_representative: Credential,
    refund: Lovelace,
  }
  // Register a new stake pool
  RegisterStakePool {
    // The hash digest of the stake pool's cold (public) key
    stake_pool: StakePoolId,
    // The hash digest of the stake pool's VRF (public) key
    vrf: VerificationKeyHash,
  }
  // Retire a stake pool. 'at_epoch' indicates in which the retirement will take place
  RetireStakePool { stake_pool: StakePoolId, at_epoch: Int }
  // Authorize a Hot credential for a specific Committee member's cold credential
  AuthorizeConstitutionalCommitteeProxy {
    constitutional_committee_member: Credential,
    proxy: Credential,
  }
  // Step down from the constitutional committee as a member.
  RetireFromConstitutionalCommittee {
    constitutional_committee_member: Credential,
  }
}

pub type Delegate {
  DelegateBlockProduction { stake_pool: StakePoolId }
  DelegateVote { delegate_representative: DelegateRepresentative }
  DelegateBoth {
    stake_pool: StakePoolId,
    delegate_representative: DelegateRepresentative,
  }
}

pub type DelegateRepresentative {
  Registered(Credential)
  AlwaysAbstain
  AlwaysNoConfidence
}
