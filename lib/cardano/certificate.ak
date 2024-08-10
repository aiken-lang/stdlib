use cardano/assets.{Lovelace}
use cardano/credential.{
  ColdCommitteeCredential, DRepCredential, HotCommitteeCredential, PoolId,
  StakeCredential, VerificationKeyHash,
}
use cardano/governance.{Delegatee}

/// An on-chain certificate attesting of some operation. Publishing
/// certificates / triggers different kind of rules; most of the time,
/// they require signatures from / specific keys.
pub type Certificate {
  // Register staking credential with an optional deposit amount
  RegisterStaking {
    delegator: StakeCredential,
    deposit_amount: Option<Lovelace>,
  }
  // Un-Register staking credential with an optional refund amount
  UnregisterStaking {
    delegator: StakeCredential,
    refund_amount: Option<Lovelace>,
  }
  // Delegate staking credential to a Delegatee
  DelegateStaking { delegator: StakeCredential, delegatee: Delegatee }
  // Register and delegate staking credential to a Delegatee in one certificate. Noter that
  // deposit is mandatory.
  RegisterAndDelegate {
    delegator: StakeCredential,
    delegatee: Delegatee,
    deposit_amount: Lovelace,
  }
  // Register a DRep with a deposit value. The optional anchor is omitted.
  RegisterDRep { representative: DRepCredential, deposit_amount: Lovelace }
  // Update a DRep. The optional anchor is omitted.
  UpdateDRep { representative: DRepCredential }
  // UnRegister a DRep with mandatory refund value
  UnregisterDRep { representative: DRepCredential, refund_amount: Lovelace }
  // A digest of the PoolParams
  PoolRegister {
    // poolId
    pool_id: PoolId,
    // pool VFR
    pool_vrf: VerificationKeyHash,
  }
  // The retirement certificate and the Epoch in which the retirement will take place
  PoolRetire { pool_id: PoolId, epoch: Int }
  // Authorize a Hot credential for a specific Committee member's cold credential
  AuthorizeHotCommittee {
    cold_memeber: ColdCommitteeCredential,
    hot_member: HotCommitteeCredential,
  }
  ResignColdCommittee { cold_member: ColdCommitteeCredential }
}
